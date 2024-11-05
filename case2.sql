use school;

select * from playstore;

-- 1.You're working as a market analyst for a mobile app development company.
--  Your task is to identify the most promising categories(TOP 5) for 
-- launching new free apps based on their average ratings.

select category, round(avg(rating),2) as 'average'  from playstore where type='Free' 
group by category
order by average desc
limit 5;

-- 2. As a business strategist for a mobile app company, your objective is to pinpoint the three categories
-- that generate the most revenue from paid apps.
-- This calculation is based on the product of the app price and its number of installations.
select category, round(sum(revenue),2) as rev from
(
select *, (Installs*Price)  as revenue from playstore where  type='paid'
)t  group by category 
order by rev desc
limit 3;

-- 3. As a data analyst for a gaming company, you're tasked with calculating the percentage of games 
-- within each category. 
-- This information will help the company understand the distribution of gaming apps across different categories.

select * , round((cnt/(select count(*) from playstore))*100,2)as 'percentage' from
(
select category , count(category) as 'cnt' from playstore group by category
)m;

-- practice
select sum(percentage) from (

select * , (cnt/(select count(*) from playstore))*100 as 'percentage' from
(
select category , count(category) as 'cnt' from playstore group by category
)m)n;



-- 4. As a data analyst at a mobile app-focused market research firm, 
-- you'll recommend whether the company should develop paid or free apps for each category based 
-- on the  ratings of that category

with freeapp as
(
 select category, round(avg(rating),2) as 'avg_rating_free' from playstore where type ='Free'
 group by category
),
paidapp as
( 
 select category, round(avg(rating),2) as 'avg_rating_paid' from playstore where type ='Paid'
 group by category
)

select *, if(avg_rating_free>avg_rating_paid,'Develop Free app','Develop Paid app') as 'Development' from
(
select f.category,f.avg_rating_free, p.avg_rating_paid  from freeapp as f inner join paidapp  as p on f.category = p.category
)k;

-- practice 
select development, count(development) as cnt from (
with freeapp as
(
 select category, round(avg(rating),2) as 'avg_rating_free' from playstore where type ='Free'
 group by category
),
paidapp as
( 
 select category, round(avg(rating),2) as 'avg_rating_paid' from playstore where type ='Paid'
 group by category
)

select *, if(avg_rating_free>avg_rating_paid,'Develop Free app','Develop Paid app') as 'Development' from
(
select f.category,f.avg_rating_free, p.avg_rating_paid  from freeapp as f inner join paidapp  as p on f.category = p.category
)k
)l group by development;



-- 5.Suppose you're a database administrator, your databases have been hacked  and hackers are changing
 -- price of certain apps on the database , its taking long for IT team to 
-- neutralize the hack , however you as a responsible manager  dont want your data to be changed , 
-- do some measure where the changes in price can be recorded as you cant 
-- stop hackers from making changes

-- creating table. -- pricechangelog
-- play 
-- for update
DELIMITER //   
CREATE TRIGGER price_change_update
AFTER UPDATE ON play
FOR EACH ROW
BEGIN
    INSERT INTO pricechangelog (app, old_price, new_price, operation_type, operation_date)
    VALUES (NEW.app, OLD.price, NEW.price, 'update', CURRENT_TIMESTAMP);
END;
//
DELIMITER ;

-- insert 
DELIMITER //   
CREATE TRIGGER price_change_insert
AFTER INSERT ON play
FOR EACH ROW
BEGIN
    INSERT INTO pricechangelog (app, old_price, new_price, operation_type, operation_date)
    VALUES (NEW.app, NULL, NEW.price, 'insert', CURRENT_TIMESTAMP);
END;
//
DELIMITER ;

-- delete
DELIMITER //   
CREATE TRIGGER price_change_delete
AFTER DELETE ON play
FOR EACH ROW
BEGIN
    INSERT INTO pricechangelog (app, old_price, new_price, operation_type, operation_date)
    VALUES (OLD.app, OLD.price, NULL, 'delete', CURRENT_TIMESTAMP);
END;
//
DELIMITER ;

SET SQL_SAFE_UPDATES = 0;
UPDATE play
SET price = 4
WHERE app = 'Infinite Painter';

UPDATE play
SET price = 5
WHERE app = 'Sketch - Draw & Paint';

DELETE FROM play
WHERE app = 'Photo Editor & Candy Camera & Grid & ScrapBook';

insert into play values('saroj','saroj',3.5,1000,'15m',1000,'Free',0,'Everyone','Art','2018-01-15','2.0.0','4.0.4 and up');

select * from playstore where app='Infinite Painter';
select * from pricechangelog;

SHOW TRIGGERS; -- show the different triggers 


-- 6. your IT team have neutralize the threat,  however hacker have made some 
-- changes in the prices, but becasue of your measure you have noted the changes , now you want
-- correct data to be inserted into the database.

 -- drop trigger price_change_update;  -- we have to drop the trigger first 
with updated_data as
(
 select * from pricechangelog where operation_type='update' 
 )
 UPDATE play AS p1
INNER JOIN updated_data AS p2 ON p1.app = p2.app
SET p1.price = p2.old_price;      -- step 2

select * from  play where app='Sketch - Draw & Paint';

-- 
-- 7. As a data person you are assigned the task to investigate the correlation
--  between two numeric factors: app ratings and the quantity of reviews.
SET @x = (SELECT ROUND(AVG(rating), 2) FROM playstore);
SET @y = (SELECT ROUND(AVG(reviews), 2) FROM playstore); 
with t as 
(
	select  *, round((rat*rat),2) as 'sqrt_x' , round((rev*rev),2) as 'sqrt_y' from
	(
		select  rating , @x, round((rating- @x),2) as 'rat' , reviews , @y, round((reviews-@y),2) as 'rev'from playstore
	)a                                                                                                                        
)
-- select * from  t
select  @numerator := round(sum(rat*rev),2) , @deno_1 := round(sum(sqrt_x),2) , @deno_2:= round(sum(sqrt_y),2) from t ; -- setp 4 
select round((@numerator)/(sqrt(@deno_1*@deno_2)),2) as corr_coeff

-- 8. Your boss noticed  that some rows in genres columns have multiple generes in them, which was creating issue when
--  developing the  recommendor
 -- system from the data
-- he/she asssigned you the task to clean the genres column and make two genres out of it, rows
-- that have only one genre will have other column as blank.

DELIMITER //
CREATE FUNCTION f_name(a VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    SET @l = LOCATE(';', a);

    SET @s = IF(@l > 0, LEFT(a, @l - 1), a);

    RETURN @s;
END//
DELIMITER ;

-- function for second genre
DELIMITER //
create function l_name(a varchar(100))
returns varchar(100)
deterministic 
begin
   set @l = locate(';',a);
   set @s = if(@l = 0 ,' ',substring(a,@l+1, length(a)));
   return @s;
end //
DELIMITER ;
select app, genres, f_name(genres) as 'gene 1', l_name(genres) as 'gene 2' from playstore;

-- break down the formulas 
select LOCATE(':','saro:j'); -- 5 
select locate(':','giri') ; -- 0 
select substring('saroj',3,5);-- string ,starting index , ending strings 
select length('saroj'); -- length ofn the strings
select left('saroj',3);
select trim('  saroj                  '); -- remove the whitye spaces 
select '           saroj             ';

SELECT SUBSTRING_INDEX('apple,banana,cherry', ',', 1) AS first_item;  -- Returns 'apple'

SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('apple,banana,cherry', ',', 2), ',', -1) AS second_item;  -- Returns 'banana'
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('apple,banana,cherry', ',', 3), ',', -1) AS thiord_item;
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('apple,banana,cherry,guava', ',', 4), ',', -1) AS fourth_item;

/* -- funxctions 
DELIMITER //
CREATE FUNCTION split_string(str TEXT, delimiter VARCHAR(12), pos INT) 
RETURNS TEXT
BEGIN
    RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(str, delimiter, pos), delimiter, -1);
END //
DELIMITER ;  */

select SUBSTRING_INDEX('apple,banana,cherry', ',', 2); -- apple,banana
select SUBSTRING_INDEX('apple,banana,cherry', ',', 3); -- apple banana cherry 
select SUBSTRING_INDEX('apple,banana,cherry', ',', -1); --  cherry 
select SUBSTRING_INDEX('apple,banana,cherry', ',', -2); --  cherry ,banana

select SUBSTRING_INDEX(SUBSTRING_INDEX('apple,banana,cherry', ',', 2),',',-1)


-- 9. Your senior manager wants to know which apps are  not performing as par in their particular
-- category,
 -- however he is not interested in handling too many files or
-- list for every  category and he/she assigned  you with a task of creating a dynamic tool 
-- where he/she  can input a category of apps he/she  interested in and 
-- your tool then provides real-time feedback by
-- displaying apps within that category that have ratings lower than the average rating for
 -- that specific category

DELIMITER //
create PROCEDURE checking(in  cate varchar(30))
begin
		set @c=
		(
		select average from 
		 (
			select category, round(avg(rating),2)  as average from playstore group by category
		 )m where category = cate
		);
        
        select * from playstore where category=cate and rating <@c;

end//
DELIMITER ;

call checking('events');

select distinct(category) from play;

-- break down 
select category, round(avg(rating),2)  as average from playstore group by category;

select * from playstore where category='Business';

-- store in the variables  
select average from 
		 (
			select category, round(avg(rating),2)  as average from playstore group by category
		 )m where category = 'Business';


-- some string functions in mysql 
select LENGTH('saroj');
select SUBSTRING('saroj', 2, 5);
select  CONCAT('saroj','giri','kushma');
-- trim , upper , lower , 

SELECT REPLACE('Hello, World!', 'World', 'MySQL');  -- Returns 'Hello, MySQL!'

SELECT LEFT('Hello, World!', 5);  -- Returns 'Hello'
SELECT RIGHT('Hello, World!', 6);  -- Returns 'World!'

SELECT FIND_IN_SET('banana', 'apple,guava,banana,cherry');  -- Returns 3

SELECT SOUNDEX('Smith');  -- Returns 'S530'
SELECT REVERSE('Hello');  -- Returns 'olleH'





 -- SET @x = NULL;
-- select @x=(select Category  from play where rating>4.0 );  not possibles 
