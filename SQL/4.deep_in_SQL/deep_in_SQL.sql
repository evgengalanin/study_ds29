--=============== МОДУЛЬ 4. УГЛУБЛЕНИЕ В SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--База данных: если подключение к облачной базе, то создаете новые таблицы в формате:
--таблица_фамилия, 
--если подключение к контейнеру или локальному серверу, то создаете новую схему и в ней создаете таблицы.

create schema lecture_4_galanin

-- Спроектируйте базу данных для следующих сущностей:
-- 1. язык (в смысле английский, французский и тп)
-- 2. народность (в смысле славяне, англосаксы и тп)
-- 3. страны (в смысле Россия, Германия и тп)


--Правила следующие:
-- на одном языке может говорить несколько народностей
-- одна народность может входить в несколько стран
-- каждая страна может состоять из нескольких народностей

 
--Требования к таблицам-справочникам:
-- идентификатор сущности должен присваиваться автоинкрементом
-- наименования сущностей не должны содержать null значения и не должны допускаться дубликаты в названиях сущностей
 
--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ

create table language (
	language_id serial primary key,
	language_name varchar(50) not null unique
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ

insert into language (language_name)
values
	('Французский язык'),
	('Испанский язык'),
	('Русский язык'),
	('Арабский язык'),
	('Португальский язык'),
	('Немецкий язык'),
	('Английский язык'),
	('Китайский язык')
	
--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ

create table nation (
	nation_id serial primary key,
	nation_name varchar(50) not null unique
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ

insert into nation (nation_name)
values
	('Бретонцы'),
	('Корсиканцы'),
	('Провансальцы'),
	('Эльзасцы'),
	('Баски'),
	('Каталонцы'),
	('Русские'),
	('Украинцы'),
	('Татары'),
	('Чуваши'),
	('Арабы'),
	('Непальцы'),
	('Филиппинцы'),
	('Португальцы'),
	('Испанцы'),
	('Бавары'),
	('Фризы'),
	('Баварцы'),
	('Штединги'),
	('Шотландцы'),
	('Гэлы'),
	('Британцы'),
	('Валлийцы'),
	('Китайцы'),
	('Тибетцы'),
	('Тайцы'),
	('Кадайцы')

--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ

create table country (
	country_id serial primary key,
	country_name varchar(50) not null unique
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ

insert into country (country_name)
select distinct country from public.country

--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table nation_language (
	nation_id int2 not null references nation (nation_id),
	language_id int2 not null references language (language_id),
	last_update timestamp default now(),
	PRIMARY KEY(language_id, nation_id)
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into nation_language (nation_id, language_id)
values
	(1, 1), (2, 1), (3, 1), (4, 1),
	(5, 2), (6, 2),
	(7, 3), (8, 3), (9, 3), (10, 3),
	(11, 4), (12, 4), (13, 4),
	(14, 5), (15, 5),
	(16, 6), (17, 6), (18, 6), (19, 6),
	(20, 7), (21, 7), (22, 7), (23, 7),
	(24, 8), (25, 8), (26, 8), (27, 8)
	

--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table nation_country (
	nation_id int2 not null references nation (nation_id),
	country_id int2 not null references country (country_id),
	last_update timestamp default now(),
	PRIMARY KEY(nation_id, country_id)
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into nation_country (nation_id, country_id)
values
	(1, 57), (2, 57), (3, 57), (4, 57),
	(5, 104), (6, 104),
	(7, 86), (8, 86), (9, 86), (10, 86),
	(11, 109), (12, 109), (13, 109),
	(14, 30), (15, 30),
	(16, 24), (17, 24), (18, 24), (19, 24),
	(20, 22), (21, 22), (22, 22), (23, 22),
	(24, 87), (25, 87), (26, 87), (27, 87)

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.

create table film_new (
	film_name varchar(255) not null,
	film_year integer not null check (film_year > 0),
	film_rental_rate numeric(4,2) default 0.99,
	film_duration integer not null check (film_duration > 0)
)

--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
select
	unnest (array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),
	unnest (array[1994, 1999, 1985, 1994, 1993]),
	unnest (array[2.99, 0.99, 1.99, 2.99, 3.99]),
	unnest (array[142, 189, 116, 142, 195])
	
--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41

update film_new 
set film_rental_rate = film_rental_rate + 1.41

--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new

delete from film_new
where film_name = 'Back to the Future'

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме



--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых

select *, round(film_duration / 60, 1)
from film_new

--ЗАДАНИЕ №7 
--Удалите таблицу film_new

drop table film_new