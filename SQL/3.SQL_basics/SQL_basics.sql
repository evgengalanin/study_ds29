--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select name as "Фамилия и Имя",
	address as "Адрес",
	city as " Город",
	country as "Страна"
from customer_list

--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select store_id as "ID магазина",
	count(customer_id) as "Количество покупателей"
from customer
group by store_id

--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select store_id as "ID магазина",
	count(customer_id) as "Количество покупателей" 
from customer
group by store_id
having count(customer_id) > 300

-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select c.store_id as "ID магазина",
	count(c.customer_id) as "Количество покупателей", 
	ct.city as "Город магазина",
	concat_ws(' ', st.first_name, st.last_name) as "Имя и фамилия продавца"
from customer c 
join store s on s.store_id = c.store_id 
join address a on a.address_id = s.address_id
join city ct on ct.city_id = a.city_id
join staff st on st.staff_id = s.manager_staff_id
group by c.store_id, a.address_id, ct.city_id, st.staff_id
having count(c.customer_id) > 300

--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select concat_ws(' ', c.last_name, c.first_name) as "Фамилия и имя покупателя",
	count(r.rental_id) as "Количество фильмов"
from rental r
join customer c on c.customer_id = r.customer_id
group by c.customer_id 
order by "Количество фильмов" desc
limit 5

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select concat_ws(' ', c.last_name, c.first_name) as "Фамилия и имя покупателя", 
	count(p.payment_id) as "Количество фильмов",
	round(sum(amount)) as "Общая стоимость платежей",
	min(amount) as "Минимальная стоимость платежа",
	max(amount) as "Максимальная стоимость платежа"
from customer c
join payment p on p.customer_id = c.customer_id 
group by c.customer_id
limit 5

--ЗАДАНИЕ №5
--Используя данные из таблицы городов составьте одним запросом всевозможные пары городов таким образом,
 --чтобы в результате не было пар с одинаковыми названиями городов. 
 --Для решения необходимо использовать декартово произведение.
 
select c1.city as "Город 1", c2.city as "Город 2"
from city c1
cross join city c2
where c1.city != c2.city

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date)
--и дате возврата фильма (поле return_date), 
--вычислите для каждого покупателя среднее количество дней, за которые покупатель возвращает фильмы.
 
select customer_id as "ID покупателя",
	round(avg(return_date::date - rental_date::date), 2) as "Среднее количество дней"
from rental
group by customer_id

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select f.title, f.rating, count(r.rental_id), sum(p.amount)
from film f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id 
join payment p on p.rental_id = r.rental_id 
group by f.film_id

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью запроса фильмы, которые ни разу не брали в аренду.

select f2.title, count(r.rental_id), sum(p.amount)
from film f
join inventory i on i.film_id = f.film_id
join rental r on r.inventory_id = i.inventory_id 
join payment p on p.rental_id = r.rental_id
right join film f2 on f2.film_id = f.film_id
where f.title is null
group by f2.film_id

--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select p.staff_id, count(p.payment_id),
	case
		when count(p.payment_id) > 7300 then 'Yes'
		else 'No'
	end
from payment p 
group by p.staff_id






