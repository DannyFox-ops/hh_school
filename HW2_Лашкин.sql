-- ============================================================
-- Домашнее задание к лекции «SQL. Продвинутый»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Лашкин Даниил Юрьевич
-- ============================================================
-- Формат: задания по порядку, каждое начинается с комментария
-- с номером; под каждым запросом — вывод (2–3 предложения).
-- Запрос без вывода не засчитывается.
-- ============================================================

SET search_path TO hh_school;


-- ============================================================
-- Блок А. Качество и подготовка данных
-- ============================================================
-- 1. Аудит качества данных · 1,5 балла
-- ============================================================

-- Перед расчётом метрик исследуйте таблицы calls и messages и найдите записи, которые могут
-- исказить дальнейший анализ.
-- Среди необычных значений могут встречаться как реальные ошибки, так и допустимые бизнессценарии. Поэтому недостаточно просто найти редкое или странное значение — нужно понять,
-- влияет ли оно на возможность использовать строку в расчётах.
-- Самостоятельно определите набор проверок. В частности, подумайте:

-- ● можно ли корректно связать событие с откликом;
-- ● согласуются ли между собой идентификаторы в связанных таблицах;
-- ● может ли событие находиться в указанной точке времени относительно отклика;
-- ● согласуются ли значения внутри одной строки между собой;
-- ● есть ли пропуски в данных, которые понадобятся дальше;
-- ● есть ли значения, заметно отличающиеся от основной массы наблюдений.
--      Для каждого найденного типа проблемы получите:
-- ● количество строк;
-- ● call_id или message_id проблемных записей;
-- ● краткий комментарий: влияет ли проблема на сам факт коммуникации или только на отдельный
--      атрибут события.
--  
--  Отдельно исследуйте call_duration успешных звонков. Для строк, где значение длительности
-- можно содержательно интерпретировать, посчитайте:
-- ● среднюю длительность;
-- ● медиану длительности;
-- ● 99-й перцентиль длительности;
-- ● количество звонков выше 99-го перцентиля;
-- ● среднюю длительность после исключения значений выше 99-го перцентиля.

-- =============================================================
-- Знакомлюсь с базой, пытаюсь понять, какие вообще есть значения

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'hh_school'
  AND table_name IN ('calls', 'messages')
ORDER BY
    table_name;

-- ============================================================= 

-- 1. Проверка звонков и связанных откликов

select count(*) filter (
           where c.call_duration is null
           ) as null_duration,
       count(*) filter (
           where c.call_duration is not null 
           ) as not_null_duration,
       min(c.call_duration) as max_duration,
       min(c.call_duration) as min_duration,
       c.status
from hh_school.calls c
group by status;
----------------------------------------------

select count(c.response_id),
       count(*) filter (
       where c.call_duration is null 
       ) as null_duration,
       count(*) filter (
       where c.call_duration is not null 
       ) as not_null_duration 
from hh_school.calls c 
inner join hh_school.responses r
     on c.response_id = r.response_id;

     
-- 2. Проверка сообщений и связанных откликов
select count(m.message_id),
       count(m.response_id)
from hh_school.messages m
left join hh_school.responses r 
       on m.response_id = r.response_id 
where r.response_id is null
      or m.response_id is null;

-- 3. Сообщения без связанного отклика

select m.message_id,
       m.response_id
from hh_school.messages m
left join hh_school.responses r
      on m.response_id = r.response_id
where m.response_id is null
   or r.response_id is null;

-- 4. Несоответствие вакансии у сообщения и отклика

select m.message_id,
       m.response_id,
       m.vacancy_id as message_vacancy_id,
       r.vacancy_id as response_vacancy_id
from hh_school.messages m
join hh_school.responses r
    on m.response_id = r.response_id
where m.vacancy_id <> r.vacancy_id;


-- 5. Несоответствие вакансии у звонка и отклика

select c.call_id,
       c.response_id,
       c.vacancy_id as call_vacancy_id,
       r.vacancy_id as response_vacancy_id
from hh_school.calls c
join hh_school.responses r
    on c.response_id = r.response_id
where c.vacancy_id <> r.vacancy_id;


-- 6. Сообщения с несуществующим работодателем или вакансией

select
    m.message_id,
    m.employer_id,
    m.vacancy_id
from hh_school.messages m
left join hh_school.employers e
    on m.employer_id = e.employer_id
left join hh_school.vacancies v
    on m.vacancy_id = v.vacancy_id
where e.employer_id is null
   or v.vacancy_id is null;


-- 7. Звонки с несуществующим работодателем или вакансией

select
    c.call_id,
    c.employer_id,
    c.vacancy_id
from hh_school.calls c
left join hh_school.employers e
    on c.employer_id = e.employer_id
left join hh_school.vacancies v
    on c.vacancy_id = v.vacancy_id
where e.employer_id is null
   or v.vacancy_id is null;

-- 9. Подозрительные данные в звонках: пропуски ключевых полей

select *
from hh_school.calls
where employer_id is null
   or applicant_id is null
   or vacancy_id is null
   or caller_role is null
   or status is null
   or call_at is null
   or call_tags is null;


-- 10. Проверка согласованности статуса звонка и длительности

select
    call_id,
    status,
    call_duration
from hh_school.calls
where (status = 'successful' and call_duration is null)
   or (status in ('unsuccessful', 'error') and call_duration is not null)
   or call_duration <= 0;


-- 11. Сообщения, отправленные раньше создания отклика

select
    m.message_id,
    m.response_id,
    m.sent_at,
    r.created_at
from hh_school.messages m
join hh_school.responses r
    on m.response_id = r.response_id
where m.sent_at < r.created_at;


-- 12. Звонки, произошедшие раньше создания отклика

select
    c.call_id,
    c.response_id,
    c.call_at,
    r.created_at
from hh_school.calls c
join hh_school.responses r
    on c.response_id = r.response_id
where c.call_at < r.created_at;


-- Анализ длительности успешных звонков
-- Среднее, медиана, 99-й процентиль,
-- количество значений выше 99-го процентиля,
-- среднее без этих значений

select percentile_cont(0.99) within group (
        order by call_duration
        ) as p99
from hh_school.calls
where status = 'successful';

-- Нахожу 99 - ый перцентиль успешных звонков

select count(*) as call_above_p99 
from   hh_school.calls 
where  status = 'successful'
       and call_duration >= 890.4;

-- Тут получаю 2 звонка выше 99 - го перцентиля

select   round(avg(call_duration ), 1)  as avg_call_duratiom
from     hh_school.calls
where    status = 'successful'
         and call_duration < 890.4;
-- Нахожу среднее время по успешным звонкам --

select round(avg(call_duration), 1) as avg_duration
from   hh_school.calls
where  status = 'successful';

-- Нахожу среднее без учета выброса

select PERCENTILE_CONT(0.5) within group(
       order by call_duration
       ) as p50
from hh_school.calls
where status = 'successful';

----------------------------------------

with successful_calls as (
                      select   call_id,
                               call_duration 
                      from     hh_school.calls
                      where    status = 'successful'
     ),
     p99 as (
         select percentile_cont(0.99) within group (
                order by call_duration
                ) as p99
         from   successful_calls 
      ),
      avg_call_duration as (
                        select   round(avg(call_duration ), 1) as avg_call_duration
                        from     successful_calls 
       ),
       calls_above_p99 as (
                       select count(*) as calls_above_p99
                       from successful_calls sc
                       cross join p99
                       where sc.call_duration > p99.p99
       ),
       median_duration as (
                       select percentile_cont(0.5) within group (
                              order by call_duration
                              ) as median_duration
                       from successful_calls
        )
select *
from avg_call_duration,
     median_duration,
     p99,
     calls_above_p99;



======================================
-- БЛОК Б. Первые запросы: SELECT, WHERE, ORDER BY
-- ============================================================
