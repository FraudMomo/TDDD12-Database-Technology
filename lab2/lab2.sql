/*Lab 2, Philip Svensson (phisv708) and Mohammed Al-Hashimi (mohal573)*/

source company_schema.sql;
source company_data.sql;

/*1. List all employees, i.e., all tuples in the jbemployee relation.*/

select * from jbemployee;

/*
+--+--------------+------+-------+---------+---------+
|id|name          |salary|manager|birthyear|startyear|
+--+--------------+------+-------+---------+---------+
|10|Ross, Stanley |15908 |199    |1927     |1945     |
|11|Ross, Stuart  |12067 |null   |1931     |1932     |
|13|Edwards, Peter|9000  |199    |1928     |1958     |
|26|Thompson, Bob |13000 |199    |1930     |1970     |
|32|Smythe, Carol |9050  |199    |1929     |1967     |
|33|Hayes, Evelyn |10100 |199    |1931     |1963     |
|35|Evans, Michael|5000  |32     |1952     |1974     |
|37|Raveen, Lemont|11985 |26     |1950     |1974     |
|55|James, Mary   |12000 |199    |1920     |1969     |
|98|Williams, Judy|9000  |199    |1935     |1969     |
+--+--------------+------+-------+---------+---------+
*/

/*2. List the name of all departments in alphabetical order. Note: by “name”
we mean the name attribute in the jbdept relation.*/

select name from jbdept order by name asc;

/*
+-----------+
|name       |
+-----------+
|Bargain    |
|Book       |
|Candy      |
|Children's |
|Children's |
|Furniture  |
|Giftwrap   |
|Jewelry    |
|Junior Miss|
|Junior's   |
+-----------+
*/

/*3. What parts are not in store? Note that such parts have the value 0 (zero)
for the qoh attribute (qoh = quantity on hand).*/

select * from jbparts where qoh = 0;

/*
+--+-----------------+-----+------+---+
|id|name             |color|weight|qoh|
+--+-----------------+-----+------+---+
|11|card reader      |gray |327   |0  |
|12|card punch       |gray |427   |0  |
|13|paper tape reader|black|107   |0  |
|14|paper tape punch |black|147   |0  |
+--+-----------------+-----+------+---+
*/

/*4. List all employees who have a salary between 9000 (included) and
10000 (included)?*/

select * from jbemployee where salary >= 9000 and salary <= 10000;

/*
+---+--------------+------+-------+---------+---------+
|id |name          |salary|manager|birthyear|startyear|
+---+--------------+------+-------+---------+---------+
|13 |Edwards, Peter|9000  |199    |1928     |1958     |
|32 |Smythe, Carol |9050  |199    |1929     |1967     |
|98 |Williams, Judy|9000  |199    |1935     |1969     |
|129|Thomas, Tom   |10000 |199    |1941     |1962     |
+---+--------------+------+-------+---------+---------+
*/

/*5. List all employees together with the age they had when they started
working? Hint: use the startyear attribute and calculate the age in the
SELECT clause.*/

select *, startyear - birthyear as startage from jbemployee;

/*
+----+------------------+------+-------+---------+---------+--------+
|id  |name              |salary|manager|birthyear|startyear|startage|
+----+------------------+------+-------+---------+---------+--------+
|10  |Ross, Stanley     |15908 |199    |1927     |1945     |18      |
|11  |Ross, Stuart      |12067 |null   |1931     |1932     |1       |
|13  |Edwards, Peter    |9000  |199    |1928     |1958     |30      |
|26  |Thompson, Bob     |13000 |199    |1930     |1970     |40      |
|32  |Smythe, Carol     |9050  |199    |1929     |1967     |38      |
|33  |Hayes, Evelyn     |10100 |199    |1931     |1963     |32      |
|35  |Evans, Michael    |5000  |32     |1952     |1974     |22      |
|37  |Raveen, Lemont    |11985 |26     |1950     |1974     |24      |
|55  |James, Mary       |12000 |199    |1920     |1969     |49      |
|98  |Williams, Judy    |9000  |199    |1935     |1969     |34      |
|129 |Thomas, Tom       |10000 |199    |1941     |1962     |21      |
|157 |Jones, Tim        |12000 |199    |1940     |1960     |20      |
|199 |Bullock, J.D.     |27000 |null   |1920     |1920     |0       |
|215 |Collins, Joanne   |7000  |10     |1950     |1971     |21      |
|430 |Brunet, Paul C.   |17674 |129    |1938     |1959     |21      |
|843 |Schmidt, Herman   |11204 |26     |1936     |1956     |20      |
|994 |Iwano, Masahiro   |15641 |129    |1944     |1970     |26      |
|1110|Smith, Paul       |6000  |33     |1952     |1973     |21      |
|1330|Onstad, Richard   |8779  |13     |1952     |1971     |19      |
|1523|Zugnoni, Arthur A.|19868 |129    |1928     |1949     |21      |
|1639|Choy, Wanda       |11160 |55     |1947     |1970     |23      |
|2398|Wallace, Maggie J.|7880  |26     |1940     |1959     |19      |
|4901|Bailey, Chas M.   |8377  |32     |1956     |1975     |19      |
|5119|Bono, Sonny       |13621 |55     |1939     |1963     |24      |
|5219|Schwarz, Jason B. |13374 |33     |1944     |1959     |15      |
+----+------------------+------+-------+---------+---------+--------+
*/

/*6. List all employees who have a last name ending with “son”.*/

select * from jbemployee where name like '%son, %';

/* No output */

/*7. Which items (note items, not parts) have been delivered by a supplier
called Fisher-Price? Formulate this query by using a subquery in the
WHERE clause.*/

select * from jbitem where supplier = (select id from jbsupplier where name = 'Fisher-Price');

/*
+---+---------------+----+-----+---+--------+
|id |name           |dept|price|qoh|supplier|
+---+---------------+----+-----+---+--------+
|43 |Maze           |49  |325  |200|89      |
|107|The 'Feel' Book|35  |225  |225|89      |
|119|Squeeze Ball   |49  |250  |400|89      |
+---+---------------+----+-----+---+--------+
*/

/*8. Formulate the same query as above, but without a subquery.*/

select jbitem.* from jbitem, jbsupplier where jbitem.supplier = jbsupplier.id and jbsupplier.name = 'Fisher-Price';

/*
+---+---------------+----+-----+---+--------+
|id |name           |dept|price|qoh|supplier|
+---+---------------+----+-----+---+--------+
|43 |Maze           |49  |325  |200|89      |
|107|The 'Feel' Book|35  |225  |225|89      |
|119|Squeeze Ball   |49  |250  |400|89      |
+---+---------------+----+-----+---+--------+
*/

/*9. List all cities that have suppliers located in them. Formulate this query
using a subquery in the WHERE clause.*/

select * from jbcity where id in (select city from jbsupplier);

/*
+---+--------------+-----+
|id |name          |state|
+---+--------------+-----+
|10 |Amherst       |Mass |
|21 |Boston        |Mass |
|100|New York      |NY   |
|106|White Plains  |Neb  |
|118|Hickville     |Okla |
|303|Atlanta       |Ga   |
|537|Madison       |Wisc |
|609|Paxton        |Ill  |
|752|Dallas        |Tex  |
|802|Denver        |Colo |
|841|Salt Lake City|Utah |
|921|San Diego     |Calif|
|941|San Francisco |Calif|
|981|Seattle       |Wash |
+---+--------------+-----+
*/

/*10. What is the name and the color of the parts that are heavier than a card
reader? Formulate this query using a subquery in the WHERE clause.
(The query must not contain the weight of the card reader as a constant;
instead, the weight has to be retrieved within the query.)*/

select name, color from jbparts where weight > (select weight from jbparts where name = 'card reader');

/*
+------------+------+
|name        |color |
+------------+------+
|disk drive  |black |
|tape drive  |black |
|line printer|yellow|
|card punch  |gray  |
+------------+------+
*/

/*11. Formulate the same query as above, but without a subquery. Again, the
query must not contain the weight of the card reader as a constant.*/

select t1.name, t1.color from jbparts t1 join jbparts t2 on t1.weight > t2.weight and t2.name = 'card reader';

/*
+------------+------+
|name        |color |
+------------+------+
|disk drive  |black |
|tape drive  |black |
|line printer|yellow|
|card punch  |gray  |
+------------+------+
*/

/*12. What is the average weight of all black parts?*/

select avg(weight) from jbparts where color = 'black';

/*
+-----------+
|avg(weight)|
+-----------+
|347.2500   |
+-----------+
*/

/*13. For every supplier in Massachusetts (“Mass”), retrieve the name and the
total weight of all parts that the supplier has delivered? Do not forget to
take the quantity of delivered parts into account. Note that one row
should be returned for each supplier.*/

select supplier.name, sum(parts.weight*supply.quan) as total_weight
from jbsupplier as supplier,
     jbsupply as supply,
     jbparts as parts,
     jbcity as city
where parts.id = supply.part
and supplier.id = supply.supplier
and supplier.city = city.id
and city.state = 'Mass'
group by supplier.name;

/*
+------------+------------+
|name        |total_weight|
+------------+------------+
|DEC         |3120        |
|Fisher-Price|1135000     |
+------------+------------+
*/

/*14. Create a new relation with the same attributes as the jbitems relation by
using the CREATE TABLE command where you define every attribute
explicitly (i.e., not as a copy of another table). Then, populate this new
relation with all items that cost less than the average price for all items.
Remember to define the primary key and foreign keys in your table!*/

create table jbavg as
select *
from jbitem
where price < (
    select avg(price)
    from jbitem
);

/*
+---+---------------+----+-----+----+--------+
|id |name           |dept|price|qoh |supplier|
+---+---------------+----+-----+----+--------+
|11 |Wash Cloth     |1   |75   |575 |213     |
|19 |Bellbottoms    |43  |450  |600 |33      |
|21 |ABC Blocks     |1   |198  |405 |125     |
|23 |1 lb Box       |10  |215  |100 |42      |
|25 |2 lb Box, Mix  |10  |450  |75  |42      |
|43 |Maze           |49  |325  |200 |89      |
|106|Clock Book     |49  |198  |150 |125     |
|107|The 'Feel' Book|35  |225  |225 |89      |
|118|Towels, Bath   |26  |250  |1000|213     |
|119|Squeeze Ball   |49  |250  |400 |89      |
|120|Twin Sheet     |26  |800  |750 |213     |
|165|Jean           |65  |825  |500 |33      |
|258|Shirt          |58  |650  |1200|33      |
+---+---------------+----+-----+----+--------+
*/

/*15. Create a view that contains the items that cost less than the average
price for items.*/

create view jbavg as
select *
from jbitem
where price < (
    select avg(price)
    from jbitem
);

/*
+---+---------------+----+-----+----+--------+
|id |name           |dept|price|qoh |supplier|
+---+---------------+----+-----+----+--------+
|11 |Wash Cloth     |1   |75   |575 |213     |
|19 |Bellbottoms    |43  |450  |600 |33      |
|21 |ABC Blocks     |1   |198  |405 |125     |
|23 |1 lb Box       |10  |215  |100 |42      |
|25 |2 lb Box, Mix  |10  |450  |75  |42      |
|43 |Maze           |49  |325  |200 |89      |
|106|Clock Book     |49  |198  |150 |125     |
|107|The 'Feel' Book|35  |225  |225 |89      |
|118|Towels, Bath   |26  |250  |1000|213     |
|119|Squeeze Ball   |49  |250  |400 |89      |
|120|Twin Sheet     |26  |800  |750 |213     |
|165|Jean           |65  |825  |500 |33      |
|258|Shirt          |58  |650  |1200|33      |
+---+---------------+----+-----+----+--------+
*/

/*16. What is the difference between a table and a view? One is static and the
other is dynamic. Which is which and what do we mean by static
respectively dynamic?*/

/*A view is a virtual table stored in the database. The view is dynamic because it updates when the tables
  used to create the view are updated, unlike a table which is static.*/

/*17. Create a view that calculates the total cost of each debit, by considering
price and quantity of each bought item. (To be used for charging
customer accounts). The view should contain the sale identifier (debit)
and the total cost. In the query that defines the view, capture the join
condition in the WHERE clause (i.e., do not capture the join in the
FROM clause by using keywords inner join, right join or left join).*/

create view total_debit as
select debit, sum(quantity * price) as total_cost
from jbdebit,
     jbsale,
     jbitem
where jbdebit.id = jbsale.debit
and jbitem.id = jbsale.item
group by debit;

/*
+------+----------+
|debit |total_cost|
+------+----------+
|100581|2050      |
|100586|13446     |
|100592|650       |
|100593|430       |
|100594|3295      |
+------+----------+
*/

/*18. Do the same as in the previous point, but now capture the join conditions
in the FROM clause by using only left, right or inner joins. Hence, the
WHERE clause must not contain any join condition in this case. Motivate
why you use type of join you do (left, right or inner), and why this is the
correct one (in contrast to the other types of joins).*/

create view total_debit as
    select debit, sum(quantity * price) as total_cost
    from jbdebit
    inner join jbsale j on jbdebit.id = j.debit
    inner join jbitem j2 on j.item = j2.id
    group by debit;

/*
+------+----------+
|debit |total_cost|
+------+----------+
|100581|2050      |
|100586|13446     |
|100592|650       |
|100593|430       |
|100594|3295      |
+------+----------+

We chose to use inner join because we only want records which have matching values in
both tables, otherwise we get tuples with null-values*/

/*19. Oh no! An earthquake!
a) Remove all suppliers in Los Angeles from the jbsupplier table. This
will not work right away. Instead, you will receive an error with error
code 23000 which you will have to solve by deleting some other
related tuples. However, do not delete more tuples from other tables
than necessary, and do not change the structure of the tables (i.e.,
do not remove foreign keys). Also, you are only allowed to use “Los
Angeles” as a constant in your queries, not “199” or “900”.*/

delete from jbsale
where jbsale.item in (
    select jbitem.id from jbitem
    inner join jbsupplier on jbitem.supplier = jbsupplier.id
    inner join jbcity on jbsupplier.city = jbcity.id
    and jbcity.name = 'Los Angeles'
);

delete from jbitem
where jbitem.supplier in (
    select jbsupplier.id from jbsupplier
    inner join jbcity on jbcity.id = jbsupplier.city
    and jbcity.name = 'Los Angeles'
);

delete from jbsupplier
where jbsupplier.city in (
    select jbcity.id from jbcity where jbcity.name = 'Los Angeles'
);

/*
jbsale:
+------+----+--------+
|debit |item|quantity|
+------+----+--------+
|100581|118 |5       |
|100581|120 |1       |
|100586|106 |2       |
|100586|127 |3       |
|100592|258 |1       |
|100593|23  |2       |
|100594|52  |1       |
+------+----+--------+

jbitem:
+---+---------------+----+-----+----+--------+
|id |name           |dept|price|qoh |supplier|
+---+---------------+----+-----+----+--------+
|11 |Wash Cloth     |1   |75   |575 |213     |
|19 |Bellbottoms    |43  |450  |600 |33      |
|21 |ABC Blocks     |1   |198  |405 |125     |
|23 |1 lb Box       |10  |215  |100 |42      |
|25 |2 lb Box, Mix  |10  |450  |75  |42      |
|43 |Maze           |49  |325  |200 |89      |
|52 |Jacket         |60  |3295 |300 |15      |
|101|Slacks         |63  |1600 |325 |15      |
|106|Clock Book     |49  |198  |150 |125     |
|107|The 'Feel' Book|35  |225  |225 |89      |
|118|Towels, Bath   |26  |250  |1000|213     |
|119|Squeeze Ball   |49  |250  |400 |89      |
|120|Twin Sheet     |26  |800  |750 |213     |
|121|Queen Sheet    |26  |1375 |600 |213     |
|127|Ski Jumpsuit   |65  |4350 |125 |15      |
|165|Jean           |65  |825  |500 |33      |
|258|Shirt          |58  |650  |1200|33      |
|301|Boy's Jean Suit|43  |1250 |500 |33      |
+---+---------------+----+-----+----+--------+

jbsupplier:
+---+------------+----+
|id |name        |city|
+---+------------+----+
|5  |Amdahl      |921 |
|15 |White Stag  |106 |
|20 |Wormley     |118 |
|33 |Levi-Strauss|941 |
|42 |Whitman's   |802 |
|62 |Data General|303 |
|67 |Edger       |841 |
|89 |Fisher-Price|21  |
|122|White Paper |981 |
|125|Playskool   |752 |
|213|Cannon      |303 |
|241|IBM         |100 |
|440|Spooley     |609 |
|475|DEC         |10  |
|999|A E Neumann |537 |
+---+------------+----+
*/

/* b) Explain what you did and why. */

/* We removed tuples from jbsale, jbitem and jbsupplier in that order because
jbsale is dependent on jbitem and jbitem is dependent on jbsupplier. That way
we can successfully remove suppliers from Los Angeles without any errors. */

/*20. An employee has tried to find out which suppliers have delivered items
that have been sold. To this end, the employee has created a view and
a query that lists the number of items sold from a supplier.
Now, the employee also wants to include the suppliers that have
delivered some items, although for whom no items have been sold so
far. In other words, he wants to list all suppliers that have supplied any
item, as well as the number of these items that have been sold. Help
him! Drop and redefine the jbsale_supply view to also consider suppliers
that have delivered items that have never been sold.

Hint: Notice that the above definition of jbsale_supply uses an (implicit)
inner join that removes suppliers that have not had any of their delivered
items sold.
*/

create view jbsale_supply(supplier, item, quantity) as
    select jbsupplier.name, jbitem.name, ifnull(jbsale.quantity, 0)
    from jbsupplier, jbitem
    left outer join jbsale
    on jbsale.item = jbitem.id
    where jbsupplier.id = jbitem.supplier;

select supplier, sum(quantity) as sum
from jbsale_supply2
group by supplier;
