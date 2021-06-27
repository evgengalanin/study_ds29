-- 1. В каких городах больше одного аэропорта?
----------------------------------------------

select city,
	string_agg (a.airport_name, ', ' order by a.airport_name) airports,
	count(a.airport_name) quantity
from airports a 
group by city
having count(a.airport_name) > 1


-- Описание:
-- Взял таблицу airports, сгруппировал по колонке city, и отфильтровал по условию, что количество строк больше 1.



-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? (Подзапрос)
----------------------------------------------------------------------------------------------------------

select distinct departure_airport as airport_code, a2.airport_name 
from flights f 
left join airports a2 on a2.airport_code = f.departure_airport
where aircraft_code = (
	select aircraft_code 
	from aircrafts
	where range = (
		select max(range) from aircrafts 
	)
)


-- Описание:		
-- Присоединил к таблице flights таблицу airports, по airport_code к колонке flights.departure_airport приняв, 
-- что flights.arrival_airport содержит дублирующую информацию (если есть рейс из А в Б, то будет из Б в А).
-- И добавил условие с подзапросом (и ещё одним вложенным),
-- что aircraft_code должен быть равен коду судна с максимальной дальностью перелёта.
	


-- 3. Вывести 10 рейсов с максимальным временем задержки вылета. (Оператор LIMIT)
---------------------------------------------------------------------------------

select flight_no, (actual_departure - scheduled_departure) as delay
from flights f
where actual_departure is not null
order by delay desc 
limit 10


-- Описание:
-- Из таблицы flights взял разницу delay между запланированным временем вылета и реальным, при условии,
-- что реальное время вылета is not null:
-- у каждого рейса есть запланированное время вылета scheduled_departure, а реальное actual_departure может отсутствовать.
-- Далее применил сортировку по колонке delay по убыванию и вывел в результат первые 10 значений.



-- 4. Были ли брони, по которым не были получены посадочные талоны? (Верный тип JOIN)
-------------------------------------------------------------------------------------

select distinct b.book_ref
from bookings b
join tickets t on t.book_ref = b.book_ref
left join boarding_passes bp on bp.ticket_no = t.ticket_no
where boarding_no is null


-- Описание:
-- К таблице bookings присоединяем tickets и ticket_flights, и получаем все перелёты по всем бронированиям.
-- Присоединив boarding_passes получим посадочные талоны для всех перелётов.
-- Left join чтобы увидеть пустые строки в boarding_passes.



-- 5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров
-- из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма -
-- сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.
-- (Оконная функция, подзапросы или cte)
------------------------------------------------------------------------------------------------------
	
with
	c1 as --получаем количество мест для каждого рейса исходя из типа самолёта
		(
		select f.flight_id, count(s.seat_no) 
		from flights f 
		join aircrafts a on a.aircraft_code = f.aircraft_code
		join seats s on s.aircraft_code = a.aircraft_code
		group by f.flight_id
		),
	c2 as --узнаём сколько мест было занято, в соответствии с посадочными талонами
		( 
		select f.flight_id, count(bp.boarding_no)
		from flights f 
		left join ticket_flights tf on tf.flight_id = f.flight_id
		left join boarding_passes bp on bp.flight_id = tf.flight_id and bp.ticket_no = tf.ticket_no
		group by f.flight_id
)
select f.departure_airport airport,
	f.scheduled_departure,
	sum(sum(c2.count)) over (partition by f.departure_airport, f.scheduled_departure order by f.scheduled_departure),
	f.flight_id,
	(c1.count - c2.count) free_seats_quantity,
	((c1.count - c2.count)::numeric/c1.count*100)::numeric(4) free_seats_percent
from flights f
join c1 on c1.flight_id = f.flight_id 
join c2 on c2.flight_id = f.flight_id
where f.status = 'Arrived' or f.status = 'Departed'
group by f.flight_id, c1.count, c2.count
		
		
-- Описание:
-- В с1 получаем количество мест для каждого рейса исходя из типа самолёта, выполняющего рейс.
-- В с2 узнаём сколько мест было занято, в соответствии с посадочными талонами.
-- Вычисляем процент свободных мест.
-- Оконная функция для суммарного накопления.



-- 6. Найдите процентное соотношение перелётов по типам самолетов от общего количества.(Подзапрос, оператор ROUND)
-------------------------------------------------------------------------------------------------------------------

select a.model,
	round((count(1)::numeric/(select count(1) from flights))*100, 2) ratio_percent 
from flights f
join aircrafts a on a.aircraft_code = f.aircraft_code
group by a.model


-- Описание:
-- Подзапросом достал общее количество перелётов в знаменатель.



-- 7. Были ли города, в которые можно добраться бизнес-классом дешевле, чем эконом-классом в рамках перелета? (CTE)
---------------------------------------------------------------------------------------------------------------------

with ce as (
		select flight_id, amount 
		from ticket_flights tf
		where tf.fare_conditions = 'Economy'),
	cb as (
		select flight_id, amount 
		from ticket_flights tf
		where tf.fare_conditions = 'Business')	
select distinct a.city
from flights f
join ce on ce.flight_id = f.flight_id 
join cb on cb.flight_id = f.flight_id
join airports a on a.airport_code = f.arrival_airport
where cb.amount < ce.amount


-- Описание:
-- В двух CTE достал стоимость эконома и бизнеса для каждого перелёта.
-- К таблице flights присоединил полученные CTE и таблицу airports.
-- Написал условие, что стоимость перелёта бизнесом меньше эконома.
-- В результат вывел город.
-- Результат пустой. Ответ нет - таких городов не было.



-- 8. Между какими городами нет прямых рейсов? (Декартово произведение в предложении FROM,
-- самостоятельно созданные представления, оператор EXCEPT)
-------------------------------------------------------------------------------------------

create view unrelated_cities as select a1.city city_1, a2.city city_2
	from airports a1, airports a2
	where a1.airport_code != a2.airport_code
	except select t.city_1, t.city_2 
	from (select distinct a1.city city_1, a2.city city_2
			from flights f 
			join airports a1 on a1.airport_code = f.departure_airport
			join airports a2 on a2.airport_code = f.arrival_airport
	) t

select * from unrelated_cities


-- Описание:
-- Из таблицы рейсов в подзапросе получаю две колонки городов, между которыми есть прямые рейсы.
-- С помощью декартова произведения получаю все возможные комбинации городов.
-- Исключаю те города, что получил из таблицы рейсов, из тех, что получены декартовым.
-- Всё оборачиваю в представление.



-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью
-- перелетов  в самолетах, обслуживающих эти рейсы. (Оператор RADIANS или использование sind/cosd, CASE)
------------------------------------------------------------------------------------------------------------------------

select
	t.departure_airport,
	t.arrival_airport,
	t.round,
	t.range,
	case
		when t.round > t.range then 'oops'
		else 'yahoo'
	end
from (select
		distinct on (f.departure_airport, f.arrival_airport)
		f.departure_airport,
		f.arrival_airport,
		round(acos(sin(radians(a.latitude))*sin(radians(a2.latitude))
			+ cos(radians(a.latitude))*cos(radians(a2.latitude))*cos(radians(a.longitude - a2.longitude)))*6371),
		a3.range
	from flights f 
	join airports a on a.airport_code = f.departure_airport
	join airports a2 on a2.airport_code = f.arrival_airport
	join aircrafts a3 on a3.aircraft_code = f.aircraft_code) t


-- Описание:
-- В подзапросе получаю таблицу аэропортов, между которыми выполняются рейсы,
-- с расстояниями между ними и максимальной дальностью полёта воздушного судна выполняющего рейс.
-- И вывожу в результат всю эту таблицу целиком, добавив с помощью CASE столбец сравнения.



