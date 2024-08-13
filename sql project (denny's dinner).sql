
CREATE DATABASE DANNYS_DINER
GO
DROP TABLE sales
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  select * from sales
  select * from menu
  select * from members

  --case study 
--1. what is the total amount each customer spent at the resturant ?
select customer_id, sum(price) as total_amount_spent
from sales s
inner join menu m
on s.product_id=m.product_id
group by s.customer_id

--2. how many days has each customer visited the restaurant ?

select customer_id ,count(distinct order_date) as num_days
from sales
group by customer_id

--3. what was the first item from the menu puschased by each customer 

create view temp as 
select s.customer_id,m.product_name,
ROW_NUMBER() OVER (PARTITION BY  s.customer_id order by s.order_date) as row_num
from sales s 
join menu m
on s.product_id=m.product_id
select * from temp
select (customer_id) ,product_name from temp where row_num=1

--4. what is the most purchased item on the menu and how many times was itpurchased by all customer ?


select m.product_name ,count(m.product_name) as product_count
from sales s
join menu m
on s.product_id =m.product_id
group by m.product_name
order by count(m.product_name) desc

--5. which item was the most popular for each customer ?
create view temp2 as
select s.customer_id ,m.product_name,
count(*) as order_count,
DENSE_RANK() over(partition by s.customer_id order by count(*) desc) as rn
from sales s
join menu m
on s.product_id=m.product_id
GROUP By s.customer_id,m.product_name

select product_name,rn from temp2 where rn=1
select customer_id ,product_name from temp2 where order_count =3
--6 which item was purchased first by the customer after they become a member ?
create view temp3 as
select s.customer_id, m.product_name, s.order_date, mb.join_date,
dense_rank() over(partition by s.customer_id order by order_date) as rn
from  menu m
join sales s
on m.product_id=s.product_id
join members mb
on s.customer_id=mb.customer_id
where s.order_date>mb.join_date
select customer_id ,product_name from temp3 where rn=1

--7. which item was purchased just bebore the customer became a member ?
create view temp4 as
select s.customer_id, m.product_name, s.order_date, mb.join_date,
dense_rank() over(partition by s.customer_id order by order_date desc) as rn
from  menu m
join sales s
on m.product_id=s.product_id
join members mb
on s.customer_id=mb.customer_id
where s.order_date<mb.join_date
select customer_id ,product_name from temp4 where rn=1

--8.what is the total items and amount spent for each member before they become a member?

select s.customer_id,
s.order_date,
mb.join_date,
count(m.product_id) as total_item_ordered,
sum(price) as total_amount_spent
from menu m
join sales s
on m.product_id=s.product_id
join members mb
on s.customer_id=mb.customer_id
where s.order_date <mb.join_date
group by s.customer_id,s.order_date, mb.join_date

 
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier how many points would each customerr have ?

select s.customer_Id, m.product_name,m.price ,
case
   when m.product_name='sushi' then  m.price*10*2
   else m.price*10
   end as points 
from sales s
join menu m
on s.product_id=m.product_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi. How many points do customer A and B have at the end of january ?

select s.customer_id, m.product_name, m.price, order_date ,join_date ,
case 
   when s.order_date between mb.join_date and DATEADD(day, 7, mb.join_date) then m.price*10*2
   when m.product_name='sushi' then m.price*10*2
   else m.price*10
   end as points
   from menu m
   join sales s
   on s.product_id=m.product_id
   join members mb
   on s.customer_id=mb.customer_id
   where order_date < '2021-02-01'

--11. Determine the name and price of the product ordered by each customer on all order dates & find out whether the 
--customer was a member on the order date or not
select s.customer_id, s.order_date,m.product_name,m.price,
case 
    when mb.join_date <=s.order_date then 'y'
	else 'N'
	end as member
from menu m
join sales s
on s.product_id=m.product_id
 left join members mb
on mb.customer_id =s.customer_id

--12. Rank the previous output from Q.11 based on the order_date for each customer .
--display null if customer was not a member when dish was ordered
drop  view temp6
create view temp6 as
select  s.customer_id,s.order_date,m.product_name,m.price,
case 
    when mb.join_date <=s.order_date then 'y'
	else 'N'
	end as member_status
from menu m
join sales s
on s.product_id=m.product_id
 left join members mb
on mb.customer_id =s.customer_id
select * ,
case
    when temp6.member_status ='y' then rank() 
	over(partition by customer_id ,member_status order by order_date)
	else null
	end as ranking
from temp6
