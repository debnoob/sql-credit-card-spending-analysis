select * from credit_card_transcations;
--
--Total Records and Column Structure 
select count(*) as total_transaction from credit_card_transcations;

--Understanding the data structure
select top 10* from credit_card_transcations;

--check for unique values in key columns  (card types,cities and expense types)
select count(distinct card_type) as unique_card_type, count(distinct city) as unique_cities, count(distinct exp_type) as unique_expense_type, count(distinct gender) as unique_gender from credit_card_transcations

--check for null/missing  values in columns
select
    count(*) - count(city) as missing_city,
    count(*) - count(card_type) as missing_card_type,
    count(*) - count(exp_type) as missing_exp_type,
    count(*) - count(gender) as missing_gender,
    count(*) - count(amount) as missing_amount
from credit_card_transcations;
