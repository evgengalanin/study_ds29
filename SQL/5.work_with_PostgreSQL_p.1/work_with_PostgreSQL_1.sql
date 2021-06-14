--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Cделайте запрос к таблице payment. 
--Пронумеруйте все продажи от 1 до N по дате продажи.

select payment_id, payment_date, row_number() over (order by payment_date)
from payment p
	
--ЗАДАНИЕ №2
--Используя оконную функцию добавьте колонку с порядковым номером
--продажи для каждого покупателя,
--сортировка платежей должна быть по дате платежа.

select payment_id, payment_date, customer_id, row_number() over (partition by customer_id order by payment_date)
from payment p
	
--ЗАДАНИЕ №3
--Для каждого пользователя посчитайте нарастающим итогом сумму всех его платежей,
--сортировка платежей должна быть по дате платежа.

select customer_id, payment_id, payment_date, amount, 
	sum(amount) over (partition by customer_id order by payment_date)
from payment p

--ЗАДАНИЕ №4
--Для каждого покупателя выведите данные о его последней оплате аренды.

select customer_id, payment_id, payment_date, amount
from (select customer_id, payment_id, payment_date, amount,
	row_number() over (partition by customer_id order by payment_date desc)
	from payment p) t
where t.row_number = 1

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника магазина
--стоимость продажи из предыдущей строки со значением по умолчанию 0.0
--с сортировкой по дате продажи

select staff_id, payment_id, payment_date, amount,
	lag(p.amount, 1, 0.) over (partition by staff_id order by payment_date) as last_amount
from payment p 

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за март 2007 года
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (дата без учета времени)
--с сортировкой по дате продажи

select staff_id, date(p.payment_date), sum(p.amount),
	sum(sum(p.amount)) over (partition by p.staff_id order by date(p.payment_date))
from payment p 
where extract (year from p.payment_date) = 2007 and extract(month from p.payment_date) = 3
group by p.staff_id, date(p.payment_date)
		
--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

with c1 as(
	select c.customer_id, c3.country_id, count(i.film_id), sum(p.amount), max(r.rental_date)
	from customer c 
	join rental r on r.customer_id = c.customer_id 
	join inventory i on i.inventory_id = r.inventory_id 
	join payment p on p.rental_id = r.rental_id 
	join address a on a.address_id = c.address_id 
	join city c2 on c2.city_id = a.city_id 
	join country c3 on c3.country_id = c2.country_id
	group by c.customer_id, c3.country_id),
c2 as(
	select customer_id, country_id,
		row_number() over (partition by country_id order by count) cf,
		row_number() over (partition by country_id order by sum) sa,
		row_number() over (partition by country_id order by max) md
	from c1
)
select c.country, c_1.customer_id, c_2.customer_id, c_3.customer_id
from country c 
left join c2 c_1 on c_1.country_id = c.country_id and c_1.cf = 1
left join c2 c_2 on c_2.country_id = c.country_id and c_2.sa = 1
left join c2 c_3 on c_3.country_id = c.country_id and c_3.md = 1
order by 1

-- ВТОРОЙ ВАРИАНТ

with c as (
	with c1 as (
		select c.customer_id, c3.country_id, count(i.film_id), sum(p.amount), max(r.rental_date),
		max(count(i.film_id)) over (partition by c3.country_id) mc,
		max(sum(p.amount)) over (partition by c3.country_id) ma,
		max(max(r.rental_date)) over (partition by c3.country_id) md,
		c3.country
		from customer c 
		join rental r on r.customer_id = c.customer_id 
		join inventory i on i.inventory_id = r.inventory_id 
		join payment p on p.rental_id = r.rental_id 
		join address a on a.address_id = c.address_id 
		join city c2 on c2.city_id = a.city_id 
		join country c3 on c3.country_id = c2.country_id
		group by c.customer_id, c3.country_id)
	select country_id, country,
		case
			when count = mc then customer_id
		end a,
		case
			when sum = ma then customer_id
		end b,
		case
			when max = md then customer_id
		end c
		from c1)
select country.country, string_agg(a::text, ', '), string_agg(b::text, ', '), string_agg(c::text, ', ')
from country
left join c on c.country_id = country.country_id
group by country.country

