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
join ticket_flights tf on tf.ticket_no = t.ticket_no
left join boarding_passes bp on bp.flight_id = tf.flight_id and bp.ticket_no = tf.ticket_no
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
	sum(sum(c2.count)) over (partition by f.departure_airport order by f.scheduled_departure),
	f.flight_id,
	((c1.count - c2.count)::numeric/c1.count*100)::numeric(4) free_seats_percent
from flights f
join c1 on c1.flight_id = f.flight_id 
join c2 on c2.flight_id = f.flight_id
group by f.flight_id, c1.count, c2.count
		
		
-- Описание:
-- В с1 получаем количество мест для каждого рейса исходя из типа самолёта, выполняющего рейс.
-- В с2 узнаём сколько мест было занято, в соответствии с посадочными талонами.
-- Вычисляем процент свободных мест.
-- Оконная функция для суммарного накопления.



-- 6. Найдите процентное соотношение перелётов по типам самолетов от общего количества.(Подзапрос, оператор ROUND)
-------------------------------------------------------------------------------------------------------------------

select a.model,
	round((count(1)::numeric/(select count(1) from ticket_flights))*100, 2) ratio_percent 
from ticket_flights tf
join flights f on f.flight_id = tf.flight_id 
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
select a.city
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


select a1.airport_code, a2.airport_code
from airports a1, airports a2
where a1.airport_code != a2.airport_code
except select f.departure_airport, f.arrival_airport 
from flights f 




-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью
-- перелетов  в самолетах, обслуживающих эти рейсы. (Оператор RADIANS или использование sind/cosd, CASE)

select f.departure_airport, a.latitude, a.longitude,
	f.arrival_airport, a2.latitude, a2.longitude
from flights f 
join airports a on a.airport_code = f.departure_airport
join airports a2 on a2.airport_code = f.arrival_airport



select t.departure_airport, t.arrival_airport,
	acos(sin(latitude_a)*sin(latitude_b) + cos(latitude_a)*cos(latitude_b)*cos(longitude_a - longitude_b))
from (select 
	f.departure_airport,
	a.latitude as latitude_a,
	a.longitude as longitude_a,
	f.arrival_airport,
	a2.latitude as latitude_b,
	a2.longitude as longitude_b
from flights f 
join airports a on a.airport_code = f.departure_airport
join airports a2 on a2.airport_code = f.arrival_airport) t






