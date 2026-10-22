-- ============================================================
-- Домашнее задание к лекции «SQL. Введение»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Лашкин Даниил Юрьевич
-- ============================================================
-- Формат: задания по порядку, каждое начинается с комментария
-- с номером; под каждым запросом — вывод (2–3 предложения).
-- Запрос без вывода не засчитывается.
-- ============================================================

SET search_path TO hh_school;


-- ============================================================
-- БЛОК А. Разминка: термины и структура (текстом)
-- ============================================================

-- ЗАДАНИЕ А1
-- 1. Категория и конкретный тип колонок:
--    vacancies.salary_from        — категория:  Числовая        тип: INT
--    vacancies.vacancy_name       — категория:  Строковая       тип: CHAR / VARCHAR / TEXT
--    vacancies.published_at       — категория:  Дата и время    тип: DATE / DATETIME / TIMESTAMP  - лучше последние два, если нужно время
--    employers.is_accredited_it   — категория:  Логическая      тип: BOOLEAN
--    responses.created_at         — категория:  Дата и время    тип: TIMESTAMP / DATETIME
--
-- 2. Первичные ключи таблиц:
--    areas:            area_id      
--    employers:        employer_id   
--    vacancies:        vacancy_id     
--    vacancy_details:  vacancy_id   (чем особенный: Данный ключ является не только первичным в своей таблице, но и внешним, где ссылается hh_school.vacancies.vacancy_id )
--    responses:        response_id     (Переводя на русский язык: детали вакансии ссылаются на конкретные вакансии)
--
-- 3. Почему vacancy_name не может быть первичным ключом:
--     
--    Запрос для подтверждения числом:

SELECT COUNT(*)
from hh_school.vacancies;
-- Всего вакансий: 52. 
-- запрос:

SELECT vacancy_name, COUNT(*)
FROM hh_school.vacancies
group by vacancy_name;

-- Вывод:


select count(distinct vacancy_name)
from hh_school.vacancies;

-- Одинаковых вакансий 18. Это противоречит логике первичного ключа, поскольку первичный ключ - УНИКАЛЕН
-- Перевод на русский язык: Стажер разработчик, к примеру, встречается нам 5 раз, соответственно мы не можем сделать из него
-- уникальный ID. Профессии имеют одинаковое название, не смотря на то, что они могут отличаться, есть риск наткнуться на одинаковые названия.


-- 4. Что произойдёт при записи строки «по договорённости» в salary_from:
--   Запрос не будет выполнен, потому что зарплата имеет числовой тип данных, а "по договореннсоти" - строковый. Нельзя писать текст в цифры, как и наоборот
--   Хотя цифры можно преобразовать в текст, но это уже для совершенно иных целей, это уже другая история.
--   Правильная ли это фунцкия языка, что мы увидим ошибку - безусловно да. Мы можем как "испортить" саму базу, так и запутаться в вычислениях в дальнейшем


-- ============================================================
-- БЛОК Б. Первые запросы: SELECT, WHERE, ORDER BY
-- ============================================================

-- ЗАДАНИЕ Б1
-- Запрос: experience
      
select count(distinct experience)
from hh_school.vacancies
-----------------------------------

select experience
from hh_school.vacancies
where experience is not null 
group by experience


-- Запрос: employment

select employment
from hh_school.vacancies
where employment is not null 
group by employment 

-- Запрос: professional_role

select professional_role
from hh_school.vacancies
where professional_role is not null
group by professional_role 

-- Вывод:
-- В группе опыта и занятости 3 возможных значения
-- В группе профессий 5 названий professional_role
-- Битых данных, опечаток или проблем с качеством данных не обнаружено
-- Была совершена проверка на наличие строк без данных (есть ли NULL), каждая строка занята своим значением из возможных
-- Если данные были бы написаны с ошибкой или различно, то появилось бы лишнее допустимое значение, но такого нет, все значения хорошие

-- ЗАДАНИЕ Б2
-- Запрос 1: стажировки в Москве без опыта, вакансия открыта

select vacancy_id as id,
       vacancy_name as name,
       salary_from as salary,
       published_at
from hh_school.vacancies,
     hh_school.areas
where area_name in ('Москва')
      and employment = 'Стажировка'
      and closed_at is null
      and experience = 'Нет опыта'
order by published_at DESC,
         vacancy_id


-- Запрос 2: топ-10 вакансий по salary_from

select vacancy_name as name,
       professional_role as role,
       salary_from as salary,
from hh_school.vacancies
where salary_from is not null
order by salary_from desc 
limit 10;

-- Вывод:
-- Первый запрос выдал 10 открытых вакансий о стажировке без опыта в Москве, в то время как такой же запрос без Москвы выдал 50 стажировок.
-- То есть цифра увеличилась в 5 раз. При этом, названия вакансий приобрели приставку "Стажёр", что логично. 
-- Первый запрос похож на обычный поиск работы, особенно для студента. Второй же можно отнести к анализу рынка минимальных зарплат

-- ЗАДАНИЕ Б3
-- Ловушка 1. NULL — выполнить и объяснить результат
SELECT count(*) FROM hh_school.vacancies WHERE closed_at = NULL; -- у меня не работает DBeaver без указания hh_school, поэтому внес изменения
SELECT count(*) FROM hh_school.vacancies WHERE closed_at IS NULL;

-- Ловушка 2. AND / OR — выполнить и объяснить результат
SELECT count(*) FROM hh_school.vacancies  -- 2.1
WHERE area_id = 1 OR area_id = 2 AND experience = 'Нет опыта';

SELECT count(*) FROM hh_school.vacancies   -- 2.2
WHERE (area_id = 1 OR area_id = 2) AND experience = 'Нет опыта';

-- Вывод:
-- Ловушка в первой части задания, где = NULL - синтаксическая. Запрос выдаст 0, из-за чего можно подумать, что все вакансии открыты. Если бы
-- СУБД выдал ошибку, то итог можно было поправить, а здесь ошибки нет.
-- Вторая строка корректна и полностью соответствует требованиям, указывает количество вакансий, которые еще активны
-- Таким запросом мы проверяем, закрыта ли вакансия или нет.

-- 2.1. Здесь ошибка заключается в том, что оператор AND распространяется только на вторую Арею, и получается, что мы запрашиваем следующим образом:
--   - Посчитай вакансии из Area_1 или (из Area_2 но без опыта)
--     Таким образом мы получим все вакансии из первой области, с опытом и без, а из второй области получим вакансии только без опыта
-- 2.2. Этот запрос выведет нам правильное количество вакансий из областей под идентификатором 1 или 2 и без опыта.


-- ============================================================
-- БЛОК В. Агрегации и метрики
-- ============================================================

-- ЗАДАНИЕ В1
-- Запрос 1: счётчики (строки, зарплата указана, направления, работодатели)

select count(*) as количество_строк,
       count(salary_from) as зарплаты_с_нижней_границей, -- значения без данных о зарплате пропускаются
       count(distinct professional_role ) as направления,
       count(distinct employer_id ) as количество_работодателей  -- вообще самих работодателей нет в vacancies, есть только их id, можно посчитать по нему
from hh_school.vacancies 

-- Запрос 2: доля активных вакансий (без JOIN)
-- а я еще с join не разобрался, спасибо

select count(*) as количество,
       count(*) filter (where closed_at is null ) as открытые,
       count(*) filter (where closed_at is not null) as закрытые,
       round(100.0 * count(*) filter (where closed_at is null
              ) / count(*) , 1) as процент
from hh_school.vacancies 






-- Вывод:
-- Отличия в Каунтах. Каунт со звездочкой (*) считает количество всех строк, независимо от того, что в них находится. Использовал, чтобы посчитать общее количество вакансий.
-- В принципе можно считать и со строкой или id вакансий, но проще сделать звездочку
-- COUNT (строка) - считает количество значений, отличных от Null. Его я использовал, чтобы сколько посчитать зарплат с нижней границей, поскольку 
-- Мне нужно посчитать не пустые значения в зарплате, мне нужно знать - где она указана.
-- Count(distict строка) - считает количество уникальных значений. Его я применил, чтобы посчитать, какие вообще направления имеются. 

-- 	Ответ руководителю --

-- Добрый день ! --
-- На сегодняшний день у нас имеется 33 открытые вакансии и 19 закрытых, открытые вакансии составляют 63,5 % от общего числа вакансий


-- ЗАДАНИЕ В2
-- Запрос 1: направления — вакансии, работодатели, средняя зарплата

select professional_role as name,
       count(distinct employer_id) as employer,
       count(*) as amount,
       round( AVG( salary_from ), -3) as average_sakary  -- 
from hh_school.vacancies 
group by professional_role 
order by count(*) desc


-- Запрос 2: то же, только направления с ≥ 5 открытыми вакансиями (WHERE + HAVING)

select professional_role as name,
       count(distinct employer_id) as employer,
       count(*) as amount,
       round( AVG( salary_from ), -3) as average_sakary  -- 
from hh_school.vacancies 
where closed_at is null
group by professional_role 
having count(*) >= 5
order by count(*) desc

-- Вывод:
-- В первом задании я подготовил обзор рынка, но у меня возникли некие мысли насчет этого. 
--     1. Если зарплата не указана, то она не идет в расчет. Если бЫ я применил COALESCE, то статистика пошла бы под откос
--     2. Был соблазн отфильтровать рынок на условие, открыта ли вакансия или нет. Не стал этого делать, потому что от меня требуют обзор, сводку, никто
--     вроде не собирался искать работу.
--     3. Я округлил до тысяч. Так красиво. Сотые и десятые режут глаз
-- Вывод:
--      Нельзя просто так взять и написать условие в Where. Where не поддерживает агрегатные функции (такая выходит ошибка). К тому же, сортировка, где вакансий 
--  больше 5-ти идёт уже по созданным группам, поэтому having и идет после group by.
--      avg(salary) отвечает на вопрос, какая средняя зарплата в разделе, где указана зарплата, а не там где её нет. Частично ответил в первом задании
-- По анализу рынка:  Аналитики Данных и Разработчики занимают больше половины рынка. Это говорит о большом спросе на эти направления, платят им тоже неплохо.
--       Однако информации недостаточно. Я бы взял среднюю зарплату среди всех этих направлений, а так же для полноценного понимания еще и опыт, требующийся для вакансии.
--       Платят больше всем разработчикам, но каким? Нет информации. Если бы я шел на разработчика, то ожидал бы конкуренцию.
--   


-- ============================================================
-- БЛОК Г. Соединение таблиц
-- ============================================================

-- ЗАДАНИЕ Г1
-- Запрос: топ-5 по salary_from с названием компании и городом (псевдонимы таблиц)

select v.vacancy_name,
       e.employer_name,
       a.area_name,
       v.salary_from
from hh_school.vacancies v
join hh_school.employers e
    on v.employer_id = e.employer_id
join hh_school.areas a
    on v.area_id = a.area_id
where v.salary_from is NOT null 
order by v.salary_from desc
limit 5

-- Вывод:
-- Если убрать псевдонимы и оставить просто area_id, то получится ошибка, так неправильно. По началу я делал без JOIN, просто импортировал каждую таблицу, но значения перемонжились
-- и вышло 500+ строк. Связи получились без связи, беспорядочные и без ключей, a join оставляет только совпадающие данные. 


-- ЗАДАНИЕ Г2
-- Запрос 1: все работодатели, число вакансий и откликов (LEFT JOIN)

select e.employer_name,
       count(distinct v.vacancy_id )  as vacancies_count,
       count(r.response_id) as responses_count
from hh_school.employers e
left join hh_school.vacancies v
    on e.employer_id = v.employer_id
left join hh_school.responses r 
    on v.vacancy_id = r.vacancy_id 
group by e.employer_id, e.employer_name
order by responses_count DESC;

-- Запрос 2: тот же запрос с INNER JOIN

select e.employer_name,
       count(distinct v.vacancy_id) as vacancies_count,
       count(r.response_id) as responses_count
from hh_school.employers e
inner join hh_school.vacancies v
    on e.employer_id = v.employer_id
inner join hh_school.responses r 
    on v.vacancy_id = r.vacancy_id 
group by e.employer_id, e.employer_name
order by responses_count DESC;

-- Вывод:
-- Мы используем дистинкт при подсчете вакансий, чтобы количество вакансий не повторялось, если на нее прийдут отклики
-- исчезла гринэнерго, потому что у нее нет ни одного отклика. При использовании inner join отлетела эта компания, потому что у нее отсутствовало пересечение
-- Если необходимо оставить все данные из таблицы - нужно использовать левый JOIN. INNER JOIN нужно использовать тогда, когда
-- нужно найти соответствия из основной и добавочной таблицы (левой + правой)


-- ============================================================
-- БЛОК Д. Функции и финальный кейс
-- ============================================================

-- ЗАДАНИЕ Д1
-- Запрос: помесячная динамика откликов и конверсия
-- (месяц как дата, условный агрегат, nullif в знаменателе)
------------------
select status ,
       count(*) as amount
from hh_school.responses 
group by status
-------------- -----------------------------
---- проверяю сколько и какие статусы ------
--------------------------------------------

select date_trunc('month', r.created_at ) as month,
       count(*) as responses
from hh_school.responses r
group by 1
--------------------------------------------
-- проверяю количестиво месяцев и сколько---
--------------------------------------------
select date_trunc('month', r.created_at)::date as month,
       count(*) as r.responses,
       count(*) filter (
            where status = 'invited'
            ) as invitations,
       round(100.0 * count(*) filter (
            where r.status = 'invited')
            / nullif(count(*), 0),1
            ) AS convers
from hh_shool.responses r
GROUP BY 1
ORDER BY 1

-- Вывод:
-- Максимальная конверсия из отклика в приглашение наблюдается в шестом месяце и составляет около 19,5%. 
-- За этот месяц было получено 118 откликов, из которых 23 стали приглашением. 
-- При этом наибольшее абсолютное количество приглашений — 142 — наблюдалось в седьмом месяце. 
-- Это показывает, что месяц с наибольшим числом приглашений не обязательно имеет максимальную конверсию:
--  для сравнения эффективности важно учитывать долю приглашений от общего количества откликов.
--
-- ЗАДАНИЕ Д2
-- Запрос: таблица по направлениям (вакансии, отклики, приглашения,
-- откликов на вакансию, конверсия)

select
    v.professional_role,
    count(distinct v.vacancy_id) as vacancies,
    count(r.response_id) as responses,
    count(*) filter (where r.status = 'invited') as invitations,
    round(
        count(r.response_id)
        / nullif(count(distinct v.vacancy_id), 0),
        2
    ) as avg_responses_per_vacancy,
    round(
        100.0 * count(*) filter (where r.status = 'invited')
        / nullif(count(r.response_id), 0),
        1
    ) as conversion_pct
from hh_school.vacancies v
left join hh_school.responses r
    on v.vacancy_id = r.vacancy_id
group by v.professional_role
order by conversion_pct desc nulls last;


-- Письменные ответы:
-- 1. Совпадает ли направление с наибольшим числом вакансий с направлением
--    с наибольшей конверсией?
--   направление с наибольшим количеством вакансий не совпадает с направлением с максимальной конверсией 
--   Направление Аналитика Данных дает 16 ваккансий, но конверсия составляет всего 12,1 %
-- 2. Какое направление выбрать и почему (опираясь на два столбца):
--      я бы выбрал направление Тестировщика, потому что у него
--  высокая конверсия. К тому же у вакансии мало откликов, значит конкуренция будет значительно ниже
--  насколько часто вакансия получает отклики.
-- 3. Оговорка к выводу:
-- Недостаточно данных для полноценного анализа.
-- Я бы добавил зарплату, опыт и количество открытых / закрытых вакансий


-- ============================================================
-- БЛОК Е. Со звёздочкой
-- ============================================================

-- ЗАДАНИЕ Е1
-- Исходный запрос (выполнить и посмотреть результат):
-- SELECT v.professional_role,
-- count(*) AS vacancies,
-- sum(v.salary_from) AS total_salary,
-- count(r.response_id) / count(*) AS responses_per_vacancy
-- FROM vacancies v
-- JOIN responses r ON v.vacancy_id = r.vacancy_id
-- WHERE v.closed_at = NULL
-- GROUP BY 1;
--
-- Ошибки (минимум четыре):
-- 1. Where v.closed_at = Null. 
-- 2. Count (*) as vacancies
-- 3. join
-- 4. 
--
-- Исправленный запрос:
 SELECT v.professional_role,
        count(distinct v.vacancy_id ) AS vacancies,
        sum(distinct v.salary_from) AS total_salary,
        count(r.response_id) / 
               count(distinct r.vacancy_id ) AS responses_per_vacancy
 FROM hh_school.vacancies v
 inner JOIN hh_school.responses r 
      ON v.vacancy_id = r.vacancy_id
 WHERE v.closed_at is not NULL
 group by professional_role 

-- Какие два правила из лекции защитили бы от этих ошибок при написании запроса:
-- 1. Метрики и измерения. Что считаем, и как считаем, игнорируем null или нет
-- 2. Правила соединения таблиц. Inner join должен посчитать совпадения слева и справа

