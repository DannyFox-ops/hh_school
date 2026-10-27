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
-- Знакомлюсь с базой

select
    table_name,
    column_name,
    data_type
from information_schema.columns
where table_schema = 'hh_school'
  and table_name in ('calls', 'messages')
order by
    table_name;

-- ============================================================= 

-- 1. Проверка звонков и связанных откликов

select 
       count(*) filter (
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


-- Сводка проблем качества: тип проблемы, число строк и ID записей.
with issue_rows as (
    select 'call_without_valid_response'::text as issue_type,
           c.call_id::text as record_id
    from hh_school.calls c
    left join hh_school.responses r 
         on r.response_id = c.response_id
    where c.response_id is null 
         or r.response_id is null
    union all
    select 'message_without_valid_response',
            m.message_id::text
    from hh_school.messages m
    left join hh_school.responses r 
         on r.response_id = m.response_id
    where m.response_id is null 
         or r.response_id is null
    union all
    select 'call_vacancy_mismatch', 
           c.call_id::text
    from hh_school.calls c
    join hh_school.responses r 
         on r.response_id = c.response_id
    where c.vacancy_id <> r.vacancy_id
    union all
    select 'message_vacancy_mismatch',
           m.message_id::text
    from hh_school.messages m
    join hh_school.responses r 
         on r.response_id = m.response_id
    where m.vacancy_id <> r.vacancy_id
    union all
    select 'call_employer_vacancy_mismatch',
           c.call_id::text
    from hh_school.calls c
    join hh_school.vacancies v 
         on v.vacancy_id = c.vacancy_id
    where c.employer_id <> v.employer_id
    union all
    select 'message_employer_vacancy_mismatch',
           m.message_id::text
    from hh_school.messages m
    join hh_school.vacancies v 
         on v.vacancy_id = m.vacancy_id
    where m.employer_id <> v.employer_id
    union all
    select 'call_before_response',
           c.call_id::text
    from hh_school.calls c
    join hh_school.responses r 
         on r.response_id = c.response_id
    where c.call_at < r.created_at
    union all
    select 'message_before_response',
           m.message_id::text
    from hh_school.messages m
    join hh_school.responses r 
         on r.response_id = m.response_id
    where m.sent_at < r.created_at
    union all
    select 'call_status_duration_mismatch', 
           c.call_id::text
    from hh_school.calls c
    where (c.status = 'successful' 
          and c.call_duration is null)
          or (c.status in ('unsuccessful', 'error') and c.call_duration is not null)
          or c.call_duration <= 0
    union all
    select 'message_without_text',
           m.message_id::text
    from hh_school.messages m
    where m.message_text is null or trim(m.message_text) = ''
)
select issue_type,
       count(*) as issue_count,
       array_agg(record_id order by record_id) as record_ids
from issue_rows
group by issue_type
order by issue_type;

-- Вывод: пустой результат/ноль записей означает, что проблема тестом не обнаружена.
-- Не всякая аномалия исключает событие: например, пустой текст портит атрибут сообщения,
-- а неверная связь с response_id мешает отнести событие к конкретному отклику.

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

-- Итоговый расчёт длительности успешных звонков одним CTE-запросом
with successful_calls as (
    select call_id, call_duration
    from hh_school.calls
    where status = 'successful'
),
duration_stats as (
    select
        count(*) as successful_calls,
        avg(call_duration) as avg_duration,
        percentile_cont(0.5) within group (order by call_duration) as median_duration,
        percentile_cont(0.99) within group (order by call_duration) as p99
    from successful_calls
),
outlier_stats as (
    select
        count(*) filter (where sc.call_duration > ds.p99) as calls_above_p99,
        avg(sc.call_duration) filter (where sc.call_duration <= ds.p99) as avg_without_outliers
    from successful_calls sc
    cross join duration_stats ds
)
select
    ds.successful_calls,
    round(ds.avg_duration::numeric, 1) as avg_duration,
    round(ds.median_duration::numeric, 1) as median_duration,
    round(ds.p99::numeric, 1) as p99,
    os.calls_above_p99,
    round(os.avg_without_outliers::numeric, 1) as avg_without_outliers
from duration_stats ds
cross join outlier_stats os;

-- Вывод по заданию 1: 181 успешный звонок, средняя длительность — 468 секунд,
-- медиана — 438 секунд, p99 — 890,4 секунды, выше p99 — 2 звонка.
-- После исключения этих двух звонков средняя — около 467 секунд. Превышение p99
-- не говорит о наличии ошибки


-- ============================================================
-- ЗАДАНИЕ 2. Единый слой коммуникаций · 0,5 балла
-- Только коммуникации работодателя в первые 7 суток после отклика.
-- Для звонка учитываем успешное соединение; для обеих таблиц проверяем
-- совпадение response_id, vacancy_id и работодателя с вакансией.
-- ============================================================

with employer_calls_7d as (
    select
           c.response_id,
           c.employer_id,
           c.call_id as event_id,
           c.call_at as event_at,
           'call'::text as event_type
    from hh_school.calls c
    join hh_school.responses r
         on r.response_id = c.response_id
         and r.vacancy_id = c.vacancy_id
    join hh_school.vacancies v
         on v.vacancy_id = r.vacancy_id
         and v.employer_id = c.employer_id
    where c.caller_role = 'employer'
         and c.status = 'successful'
         and c.call_at >= r.created_at
         and c.call_at < r.created_at + interval '7 days'
),
employer_messages_7d as (
    select
          m.response_id,
          m.employer_id,
          m.message_id as event_id,
          m.sent_at as event_at,
         'message'::text as event_type
    from hh_school.messages m
    join hh_school.responses r
         on r.response_id = m.response_id
         and r.vacancy_id = m.vacancy_id
    join hh_school.vacancies v
         on v.vacancy_id = r.vacancy_id
         and v.employer_id = m.employer_id
    where m.sender_role = 'employer'
         and m.sent_at >= r.created_at
         and m.sent_at < r.created_at + interval '7 days'
),
events as (
    select * from employer_calls_7d
    union all
    select * from employer_messages_7d
)
select
      count(*) as total_events,
      count(distinct response_id) as responses_with_communication,
      count(*) filter (where event_type = 'call') as total_calls,
      count(*) filter (where event_type = 'message') as total_messages
from events;

-- Вывод: в первые 7 суток после отклика обнаружено 1066 коммуникаций
-- работодателя. Чаще использовалась переписка: 988 сообщений против 78 звонков.

-- ============================================================
-- ЗАДАНИЕ 3. Таймлайн событий и витрина на уровне отклика · 1,5 балла
-- ============================================================
with employer_calls_7d as (
    select c.response_id, c.employer_id, c.call_id as event_id,
           c.call_at as event_at, 'call'::text as event_type
    from hh_school.calls c
    join hh_school.responses r
         on r.response_id = c.response_id and r.vacancy_id = c.vacancy_id
    join hh_school.vacancies v
         on v.vacancy_id = r.vacancy_id and v.employer_id = c.employer_id
    where c.caller_role = 'employer'
         and c.status = 'successful'
         and c.call_at >= r.created_at
         and c.call_at < r.created_at + interval '7 days'
),
employer_messages_7d as (
    select m.response_id, m.employer_id, m.message_id as event_id,
           m.sent_at as event_at, 'message'::text as event_type
    from hh_school.messages m
    join hh_school.responses r
         on r.response_id = m.response_id and r.vacancy_id = m.vacancy_id
    join hh_school.vacancies v
         on v.vacancy_id = r.vacancy_id and v.employer_id = m.employer_id
    where m.sender_role = 'employer'
         and m.sent_at >= r.created_at
         and m.sent_at < r.created_at + interval '7 days'
),
events as (
    select * from employer_calls_7d
    union all
    select * from employer_messages_7d
),
timeline as (
    select
        response_id, 
        employer_id, 
        event_id, 
        event_at, 
        event_type,
        row_number() over (
            partition by response_id order by event_at, event_type, event_id
        ) as event_number,
        lag(event_at) over (
            partition by response_id order by event_at, event_type, event_id
        ) as previous_event_at,
        lead(event_type) over (
            partition by response_id order by event_at, event_type, event_id
        ) as next_event_type,
        count(*) over (
            partition by response_id order by event_at, event_type, event_id
            rows between unbounded preceding and current row
        ) as cumulative_communications,
        first_value(event_type) over (
            partition by response_id order by event_at, event_type, event_id
            rows between unbounded preceding and unbounded following
        ) as first_event_type,
        last_value(event_type) over (
            partition by response_id order by event_at, event_type, event_id
            rows between unbounded preceding and unbounded following
        ) as last_event_type,
        count(*) over (partition by response_id) as event_count
    from events
),
response_mart as (
    select
        r.response_id,
        v.employer_id,
        v.professional_role,
        r.status as response_status,
        count(t.event_id) as communication_count,
        count(t.event_id) filter (where t.event_type = 'call') as call_count,
        count(t.event_id) filter (where t.event_type = 'message') as message_count,
        min(t.event_at) as first_communication_at,
        max(t.event_type) filter (where t.event_number = 1) as first_event_type,
        max(t.event_type) filter (where t.event_number = 2) as second_event_type,
        max(t.event_type) filter (where t.event_number = t.event_count) as last_event_type,
        round((extract(epoch from (min(t.event_at) - r.created_at)) / 3600.0)::numeric, 2)
            as hours_to_first_communication,
        round((max(extract(epoch from (t.event_at - t.previous_event_at))) / 3600.0)::numeric, 2)
            as max_gap_hours
    from hh_school.responses r
    join hh_school.vacancies v on v.vacancy_id = r.vacancy_id
    left join timeline t on t.response_id = r.response_id
    group by r.response_id, v.employer_id, v.professional_role, r.status, r.created_at
)
select
    rm.*,
    count(*) over () as control_total_responses,
    count(*) filter (where communication_count > 0) over () as control_with_communication,
    count(*) filter (where communication_count = 0) over () as control_without_communication,
    count(*) filter (where first_event_type = 'message') over () as control_first_message,
    count(*) filter (where first_event_type = 'call') over () as control_first_call
from response_mart rm
order by response_id;

-- всего откликов — 628;
-- с коммуникациями — 374;
-- без коммуникаций — 254;
-- с первым сообщением — 324;
-- с первым звонком — 50.


-- ============================================================
-- ЗАДАНИЕ 4. Рейтинг работодателей внутри направления · 1 балл
-- ============================================================
with employer_calls_7d as (
    select c.response_id, c.employer_id, c.call_id as event_id,
           c.call_at as event_at, 'call'::text as event_type
    from hh_school.calls c
    join hh_school.responses r 
         on r.response_id = c.response_id 
         and r.vacancy_id = c.vacancy_id
    join hh_school.vacancies v 
         on v.vacancy_id = r.vacancy_id 
         and v.employer_id = c.employer_id
    where c.caller_role = 'employer' 
         and c.status = 'successful'
         and c.call_at >= r.created_at 
         and c.call_at < r.created_at + interval '7 days'
),
employer_messages_7d as (
    select m.response_id, m.employer_id, m.message_id as event_id,
           m.sent_at as event_at, 'message'::text as event_type
    from hh_school.messages m
    join hh_school.responses r on r.response_id = m.response_id and r.vacancy_id = m.vacancy_id
    join hh_school.vacancies v on v.vacancy_id = r.vacancy_id and v.employer_id = m.employer_id
    where m.sender_role = 'employer'
      and m.sent_at >= r.created_at 
      and m.sent_at < r.created_at + interval '7 days'
),
events as (
    select * from employer_calls_7d 
    union all select * from employer_messages_7d
),
per_response as (
    select
        r.response_id, v.employer_id, v.professional_role, r.status,
        count(e.event_id) as communication_count,
        count(e.event_id) filter (where e.event_type = 'call') as call_count,
        count(e.event_id) filter (where e.event_type = 'message') as message_count,
        min(e.event_at) as first_communication_at,
        extract(epoch from (min(e.event_at) - r.created_at)) / 3600.0 as hours_to_first
    from hh_school.responses r
    join hh_school.vacancies v on v.vacancy_id = r.vacancy_id
    left join events e on e.response_id = r.response_id
    group by r.response_id, v.employer_id, v.professional_role, r.status, r.created_at
),
employer_metrics as (
    select
        professional_role,
        employer_id,
        count(*) as response_count,
        count(*) filter (where communication_count > 0) as responses_with_communication,
        round(100.0 * count(*) filter (where communication_count > 0)
              / nullif(count(*), 0), 1) as communication_share_pct,
        percentile_cont(0.5) within group (order by hours_to_first)
            filter (where communication_count > 0) as median_hours_to_first,
        percentile_cont(0.9) within group (order by hours_to_first)
            filter (where communication_count > 0) as p90_hours_to_first,
        round(100.0 * count(*) filter (where status = 'invited')
              / nullif(count(*), 0), 1) as invited_conversion_pct
    from per_response
    group by professional_role, employer_id
    having count(*) >= 8
),
ranked_employers as (
    select *,
        dense_rank() over (
            partition by professional_role
            order by communication_share_pct desc, median_hours_to_first asc nulls last
        ) as employer_rank
    from employer_metrics
)
select professional_role, employer_rank, employer_id, response_count,
       responses_with_communication, communication_share_pct,
       round(median_hours_to_first::numeric, 2) as median_hours_to_first,
       round(p90_hours_to_first::numeric, 2) as p90_hours_to_first,
       invited_conversion_pct
from ranked_employers
where employer_rank <= 2
order by professional_role, employer_rank, employer_id;

-- Аналитик данных: группа 1 — 109, группа 2 — 103
-- Дата-инженер: группа 1 — 106, группа 2 — 101
-- Продуктовый аналитик: группа 1 — 103, группа 2 — 102
-- Разработчик: группа 1 — 112, группа 2 — 104
-- Тестировщик: группа 1 — 107, группа 2 — 108
-- Всего наблюдений: 1055


-- ============================================================
-- ЗАДАНИЕ 5. Скорость ответа работодателя в переписке · 0,5 балла
-- ============================================================
with messages_7d as (
    select m.message_id, m.response_id, m.employer_id, m.sent_at, m.sender_role
    from hh_school.messages m
    join hh_school.responses r 
         on r.response_id = m.response_id 
         and r.vacancy_id = m.vacancy_id
    join hh_school.vacancies v 
         on v.vacancy_id = r.vacancy_id 
         and v.employer_id = m.employer_id
    where m.sent_at >= r.created_at
         and m.sent_at < r.created_at + interval '7 days'
),
message_sequence as (
    select *,
        lag(sender_role) over (partition by response_id order by sent_at, message_id) as prev_sender_role,
        lag(sent_at) over (partition by response_id order by sent_at, message_id) as prev_sent_at
    from messages_7d
),
employer_replies as (
    select employer_id,
        extract(epoch from (sent_at - prev_sent_at)) / 3600.0 as response_hours
    from message_sequence
    where sender_role = 'employer'
      and prev_sender_role = 'applicant'
      and prev_sent_at is not null
),
reply_metrics as (
    select employer_id,
        count(*) as measured_replies,
        avg(response_hours) as avg_response_hours,
        percentile_cont(0.5) within group (order by response_hours) as median_response_hours,
        percentile_cont(0.9) within group (order by response_hours) as p90_response_hours
    from employer_replies
    group by employer_id
)
select employer_id, measured_replies,
       round(avg_response_hours::numeric, 2) as avg_response_hours,
       round(median_response_hours::numeric, 2) as median_response_hours,
       round(p90_response_hours::numeric, 2) as p90_response_hours,
       sum(measured_replies) over () as total_measured_replies
from reply_metrics
order by median_response_hours, employer_id;

-- Контрольные результаты задания 5:
-- Количество строк: 11.
-- Значение в последнем столбце во всех строках: 749.
-- Максимальное значение второго столбца: 171 (группа 103).
-- Минимальное значение второго столбца: 6 (группа 105).


-- ============================================================
-- ЗАДАНИЕ 6. Сложные типы данных · 1 балл
-- 6.1 Теги звонков
-- ============================================================
with employer_calls_7d as (
     select c.call_id, c.response_id, c.employer_id, c.call_at, c.status, c.call_tags
     from hh_school.calls c
     join hh_school.responses r 
          on r.response_id = c.response_id 
          and r.vacancy_id = c.vacancy_id
     join hh_school.vacancies v 
          on v.vacancy_id = r.vacancy_id 
          and v.employer_id = c.employer_id
     where c.caller_role = 'employer'
          and c.call_at >= r.created_at
          and c.call_at < r.created_at + interval '7 days'
),
valid_calls as (
    select *
    from employer_calls_7d
    where
        (status = 'successful'
         and 'connected' = any(call_tags)
         and not ('no_answer' = any(call_tags) or 'technical_error' = any(call_tags)))
        or
        (status = 'unsuccessful'
         and 'no_answer' = any(call_tags)
         and not ('connected' = any(call_tags) or 'technical_error' = any(call_tags)))
        or
        (status = 'error'
         and 'technical_error' = any(call_tags)
         and not ('connected' = any(call_tags) or 'no_answer' = any(call_tags)))
)
select
    count(*) filter (where 'screening' = any(call_tags)) as screening_calls,
    count(*) filter (where 'interview' = any(call_tags)) as interview_calls,
    count(*) filter (where 'follow_up' = any(call_tags)) as follow_up_calls,
    count(*) filter (where 'details' = any(call_tags)) as details_calls,
    count(*) filter (where call_tags && array['screening','interview','follow_up','details']::text[])
        as calls_with_business_tag,
    round(avg(cardinality(call_tags))::numeric, 2) as avg_tags_per_valid_call
from valid_calls;

-- Контрольные результаты задания 6.1:
-- Значения: 25, 31, 29, 23, 108.
-- Итоговое значение: 4.00.

-- 6.2 Метаданные сообщений
with employer_messages_7d as (
    select m.message_id, m.employer_id, m.sent_at, m.message_meta,
           coalesce(nullif(m.message_meta ->> 'channel', ''), '[канал отсутствует]') as channel,
           case when jsonb_typeof(m.message_meta -> 'is_read') = 'boolean'
                then (m.message_meta ->> 'is_read')::boolean 
                end as is_read,
           case when jsonb_typeof(m.message_meta -> 'attachments') = 'array'
                then jsonb_array_length(m.message_meta -> 'attachments') 
                else 0 end as attachment_count
    from hh_school.messages m
    join hh_school.responses r 
         on r.response_id = m.response_id 
         and r.vacancy_id = m.vacancy_id
    join hh_school.vacancies v 
         on v.vacancy_id = r.vacancy_id 
         and v.employer_id = m.employer_id
    where m.sender_role = 'employer'
          and m.sent_at >= r.created_at
          and m.sent_at < r.created_at + interval '7 days'
)
select channel,
       count(*) as messages_count,
       count(*) filter (where is_read is not null) as read_flag_present_count,
       count(*) filter (where is_read = false) as unread_count,
       round(100.0 * count(*) filter (where is_read = false)
             / nullif(count(*) filter (where is_read is not null), 0), 1) as unread_pct_known,
       count(*) filter (where attachment_count > 0) as messages_with_attachments,
       round(100.0 * count(*) filter (where attachment_count > 0)
             / nullif(count(*), 0), 1) as attachments_pct
from employer_messages_7d
group by channel
order by channel;

-- Контрольные результаты задания 6.2:
-- mobile_app: 360 событий, 36 целевых действий (10.0%)
-- 14 дополнительных событий, показатель 3.9
-- web: 628 событий, 52 целевых действия (8.3%)
-- 25 дополнительных событий, показатель 4.0

-- ============================================================
-- ЗАДАНИЕ 7. Что связано с приглашением? · 2,5 балла
-- Гипотеза 1: у приглашённых откликов выше доля коммуникаций в первые 7 дней.
-- Гипотеза 2: у приглашённых выше доля откликов, в которых использованы оба канала
-- (звонок и сообщение). Показатель использования обоих каналов — дополнительный новый расчёт.
-- ============================================================
with employer_calls_7d as (
     select c.response_id, c.call_id as event_id, c.call_at as event_at, 'call'::text as event_type
     from hh_school.calls c
     join hh_school.responses r on r.response_id = c.response_id and r.vacancy_id = c.vacancy_id
     join hh_school.vacancies v on v.vacancy_id = r.vacancy_id and v.employer_id = c.employer_id
     where c.caller_role = 'employer' and c.status = 'successful'
           and c.call_at >= r.created_at 
           and c.call_at < r.created_at + interval '7 days'
),
employer_messages_7d as (
     select m.response_id, m.message_id as event_id, m.sent_at as event_at, 'message'::text as event_type
     from hh_school.messages m
     join hh_school.responses r on r.response_id = m.response_id and r.vacancy_id = m.vacancy_id
     join hh_school.vacancies v on v.vacancy_id = r.vacancy_id and v.employer_id = m.employer_id
     where m.sender_role = 'employer'
           and m.sent_at >= r.created_at 
           and m.sent_at < r.created_at + interval '7 days'
),
events as (
     select * from employer_calls_7d union all select * from employer_messages_7d
),
per_response as (
     select r.response_id, r.status,
        count(e.event_id) as communication_count,
        count(e.event_id) filter (where e.event_type = 'call') as call_count,
        count(e.event_id) filter (where e.event_type = 'message') as message_count,
        min(e.event_at) as first_communication_at,
        extract(epoch from (min(e.event_at) - r.created_at)) / 3600.0 as hours_to_first
     from hh_school.responses r
     left join events e 
          on e.response_id = r.response_id
     group by r.response_id, r.status, r.created_at
),
cohort_metrics as (
    select
        case when status = 'invited' then 'invited' else 'not_invited' end as outcome_group,
        count(*) as response_count,
        round(100.0 * count(*) filter (where communication_count > 0)
              / nullif(count(*), 0), 1) as pct_with_communication,
        round(avg(communication_count)::numeric, 2) as avg_communications_per_response,
        percentile_cont(0.5) within group (order by hours_to_first)
            filter (where communication_count > 0) as median_hours_to_first,
        round(100.0 * count(*) filter (where call_count > 0 and message_count > 0)
              / nullif(count(*), 0), 1) as pct_both_channels
    from per_response
    group by case when status = 'invited' then 'invited' else 'not_invited' end
)
select * from cohort_metrics order by outcome_group;

-- Вывод по гипотезам заполнить по двум строкам результата:
-- Гипотеза 1 подтверждается, если pct_with_communication выше у invited; иначе не подтверждается.
-- Гипотеза 2 подтверждается, если pct_both_channels выше у invited; иначе не подтверждается.
-- Для обеих групп показаны размеры выборки, доля коммуникаций, среднее число событий,
-- медиана времени до первого контакта и доля обоих каналов.

-- Контрольные результаты задания 7:
-- invited: 92 отклика; показатель 57.6; среднее 1.60;
-- дополнительные показатели: 52.5 и 6.5.
-- not_invited: 536 откликов; показатель 59.9; среднее 1.71;
-- дополнительные показатели: 54.73 и 7.5.


-- ============================================================
-- ЗАДАНИЕ 8. Итог исследования · 1,5 балла
-- После запуска заданий 2–7 вставить в комментарий 7–10 предложений, используя фактические числа.
-- Обязательно: >=4 числа из >=3 заданий; общий вывод, различия по работодателям/направлениям,
-- связь характеристик коммуникации с приглашением, ограничение анализа и следующий вопрос.
-- ============================================================

-- ЗАДАНИЕ 8. ИТОГ ИССЛЕДОВАНИЯ
--
-- 1. За первые семь дней после отклика найдено 1066 событий коммуникации:
-- 988 сообщений и 78 звонков. Сообщения встречались значительно чаще.
-- 2. Коммуникации были у 374 из 628 откликов, у 254 откликов их не было.
-- 3. Первым событием в 324 случаях было сообщение, в 50 случаях — звонок.
-- 4. Доля целевых действий составила 10.0% для mobile_app и 8.3% для web.
-- 5. В задании 4 показатели различались между профессиональными направлениями
-- и группами работодателей.
-- 6. В задании 7 доля откликов с коммуникацией составила 57.6% у приглашённых
-- и 59.9% у неприглашённых. Среднее число коммуникаций составило 1.60 и 1.71.
-- 7. Медианное время до первой коммуникации составило 52.5 часа у приглашённых
-- и 54.73 часа у неприглашённых. Оба канала использовались в 6.5% и 7.5% случаев.
-- 8. По рассмотренным показателям приглашённые не демонстрируют более высоких
-- значений. Эти результаты показывают связь, но не доказывают причинность.
-- 9. Ограничение исследования — возможные пропуски и ошибки исходных данных.
-- В дальнейшем стоит проверить связь между характеристиками вакансий,
-- содержанием коммуникаций и вероятностью приглашения.