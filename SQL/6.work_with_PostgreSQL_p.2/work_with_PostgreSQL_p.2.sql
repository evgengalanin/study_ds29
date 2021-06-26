--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

select film_id, title, special_features
from film f
where f.special_features @> array['Behind the Scenes']
order by f.film_id

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

select film_id, title, special_features
from film f
where array['Behind the Scenes'] <@ f.special_features
order by f.film_id

select film_id, title, special_features
from film f
where array['Behind the Scenes'] && f.special_features
order by f.film_id

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

with cte as(
	select *
	from film f
	where f.special_features @> array['Behind the Scenes']
	)
select r.customer_id, count(r.rental_id)
from cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id

--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--ПОМЕЩЕННЫЙ В ПОДЗАПРОС, который необходимо использовать для решения задания.

select r.customer_id, count(r.rental_id)
from (
	select f.*
	from film f
	where f.special_features @> array['Behind the Scenes']
	) cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id

--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view task_1 as
	select r.customer_id, count(r.rental_id)
	from (
		select f.*
		from film f
		where f.special_features @> array['Behind the Scenes']
		) cte
	join inventory i on i.film_id = cte.film_id
	join rental r on r.inventory_id = i.inventory_id
	group by r.customer_id
	order by r.customer_id
with no data

refresh materialized view task_1

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее
--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса

--1.1

explain analyze
select *
from film f
where f.special_features @> array['Behind the Scenes']
order by f.film_id
-- 92.25

--1.2

explain analyze
select *
from film f
where array['Behind the Scenes'] <@ f.special_features
order by f.film_id
--92.25

--1.3

explain analyze
select *
from film f
where array['Behind the Scenes'] && f.special_features
order by f.film_id
--92.25

--Вывод:
-- В данном случае explain analyse показывает, что для приведённых выше запросов,
-- план запроса меняется только в части фильтраци (строка Filter, где указывается применяемый оператор). 
-- Очевидно, рассмотренные операторы поиска в массиве потребляют одинаковое количество ресурсов.

--2.1 CTE

explain analyze
with cte as(
	select *
	from film f
	where f.special_features @> array['Behind the Scenes']
	)
select r.customer_id, count(r.rental_id)
from cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id

-- cost 810.84

--2.2 ПОДЗАПРОС

explain analyze
select r.customer_id, count(r.rental_id)
from (
	select f.*
	from film f
	where f.special_features @> array['Behind the Scenes']
	) cte
join inventory i on i.film_id = cte.film_id
join rental r on r.inventory_id = i.inventory_id
group by r.customer_id
order by r.customer_id

-- cost 674.48

-- Вывод:
-- Вариант с подзапросом оказался быстрее CTE.


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.






--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день




