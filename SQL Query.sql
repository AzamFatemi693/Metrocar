1. How many times was the app downloaded? 23608

select count(*)
from app_downloads


2. How many users signed up on the app? 17623

select count(*)
from signups


3. How many rides were requested through the app? 358477

select count(ride_id)
from ride_requests


4. How many rides were requested and completed through the app? 


with user_ride_status as (
select ride_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as ride_completed
from ride_requests
group by ride_id
 )
select 
	count(ride_id) as total_ride_reguested,
  sum(ride_completed) as total_ride_completed
from user_ride_status


5. How many rides were requested and how many unique users requested a ride? 
   

select count(ride_id) as total_ride_requested,
	count(distinct user_id) as total_unique_user
from ride_requests


6. What is the average time of a ride from pick up to drop off? 52 min and 37 sec 

select avg(dropoff_ts - pickup_ts)
from ride_requests


7. How many rides were accepted by a driver? 248379

select count(driver_id)
from ride_requests
where driver_id is not NULL


8. How many rides did we successfully collect payments and how much was collected? 212628 and 4251667.6 $

select count(ride_requests.ride_id), sum(purchase_amount_usd)
from ride_requests
join transactions
	using(ride_id)
where charge_status = 'Approved'


9. How many ride requests happened on each platform?

select count(ride_id), platform
from ride_requests rr
left join signups s
	using(user_id)
left join app_downloads ad
	on ad.app_download_key = s.session_id
group by platform



10. What is the drop-off from users signing up to users requesting a ride?

with total_signups AS (
  select 
  	count(distinct user_id) as total_signups
  from signups
),


users_with_ride_request AS(
  select distinct r.user_id 
  from ride_requests r
  join signups
  	using(user_id)
  ),
  
  

user_requesting_ride AS (
  select 
  	count(distinct user_id) as total_user_requesting_ride
  from users_with_ride_request
  )
  
select
	(1 - (total_user_requesting_ride :: decimal) / total_signups) * 100 as dropoff_percentage
from total_signups
cross join user_requesting_ride


11. How many users were requested and completed through the app? 

with user_ride_status as (
select user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 )
select 
	count(distinct user_id) as total_user_reguested,
  sum(user_completed) as total_user_completed
from user_ride_status


12. 

-- total_users_signed_up | total_users_ride_requested


select count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from signups s
left join ride_requests r
	using(user_id)


13.

with total as (
  select count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from signups s
left join ride_requests r
	using(user_id)
),

funnel_stage as (
  select
  	1 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	2 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  )
  
select *,
	lag(value) over(order by funnel_step) as previous_value
from funnel_stage
order by funnel_step




14.

with total as (
  select count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from signups s
left join ride_requests r
	using(user_id)
),

funnel_stage as (
  select
  	1 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	2 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  )
  
select *,
	(value :: float/lag(value) over(order by funnel_step))*100 as percentage_previous_value
from funnel_stage
order by funnel_step




15.

with total as (
  select count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
),

funnel_stage as (
  select 
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  )

select *,
	(value :: float/lag(value) over(order by funnel_step))*100 as percentage_previous_value
from funnel_stage
order by funnel_step






16.

with total as (
  select count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
),


driver_acceptance as (
select count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
),


funnel_stage as (
  select 
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
    select 
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  
  )

select *,
	(value :: float/lag(value) over(order by funnel_step))*100 as percentage_previous_value
from funnel_stage
order by funnel_step




17.

with total as (
  select count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
),


driver_acceptance as (
select count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
),

user_ride_status as (
select user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 )
,

funnel_stage as (
  select 
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select 
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select 
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  
  
  
  )

select *,
	(value :: float/lag(value) over(order by funnel_step))*100 as percentage_previous_value
from funnel_stage
order by funnel_step




18.

with total as (
  select count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
),


driver_acceptance as (
select count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
),

user_ride_status as (
select user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 ),


payment as (
  select count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
where charge_status = 'Approved'
), 

funnel_stage as (
  select 
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select 
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select 
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  
  union
  
	select 
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  )

select *,
	(value :: float/lag(value) over(order by funnel_step))*100 as percentage_previous_value
from funnel_stage
order by funnel_step

19.

with total as (
  select count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
),


driver_acceptance as (
select count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
),

user_ride_status as (
select user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 ),


payment as (
  select count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
where charge_status = 'Approved'
), 

review as (
  select count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
where charge_status = 'Approved'
  ),

funnel_stage as (
  select 
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select 
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select 
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  
  union
  
	select 
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  union 
  
  select 
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select *,
	(value :: float/lag(value) over(order by funnel_step))*100 as percentage_previous_value
from funnel_stage
order by funnel_step


20.

with total as (
  select count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
),


driver_acceptance as (
select count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
),

user_ride_status as (
select user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 ),


payment as (
  select count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
where charge_status = 'Approved'
), 

review as (
  select count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
where charge_status = 'Approved'
  ),

funnel_stage as (
  select 
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select 
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select 
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  
  union
  
	select 
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  union 
  
  select 
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select *,
	coalesce((value :: float/lag(value) over(order by funnel_step))*100, 100) as percentage_previous_value,
  coalesce((value :: float/first_value(value) over(order by funnel_step))*100, 100) as percentage_first_value
from funnel_stage
order by funnel_step


21.

with total as (
  select count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
),


driver_acceptance as (
select count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
),

user_ride_status as (
select user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 ),


payment as (
  select count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
where charge_status = 'Approved'
), 

review as (
  select count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
where charge_status = 'Approved'
  ),

funnel_stage as (
  select 
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select 
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select 
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select 
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  
  union
  
	select 
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  union 
  
  select 
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select *,
	round(coalesce((value :: float/lag(value) over(order by funnel_step))*100, 100)::numeric, 1) as percentage_previous_value,
  round(coalesce((value :: float/first_value(value) over(order by funnel_step))*100, 100)::numeric, 1) as percentage_first_value
from funnel_stage
order by funnel_step


22.

select platform, count(app_download_key) as total_download_app,
		count(app_download_key)::float / (
      select count(app_download_key) as total_download
			from app_downloads) as percentage_of_download
from app_downloads
group by platform




23.

select platform,
			downloads,
      sum(downloads) over() as total_downloads
from (
  		select platform,
  		count(*) as downloads
  		from app_downloads
  		group by platform) as result




24.

select platform,
			downloads,
      sum(downloads) over() as total_downloads,
      downloads :: float / sum(downloads) over() as pct_of_downloads
from (
  		select platform,
  		count(*) as downloads
  		from app_downloads
  		group by platform) as result



25.

select platform,
			downloads,
      sum(downloads) over() as total_downloads,
      downloads :: float / sum(downloads) over() as pct_of_downloads
from (
  		select platform,
  		count(*) as downloads
  		from app_downloads
  		group by platform) as result


or 


select platform,
				count(*) as downloads,
        sum(count(*)) over() as total_downloads, 
        count(*) :: float / sum(count(*)) over() as pct_of_downloads
from app_downloads
group by platform




26.

select 
			age_range, 
      count(*), 
      sum(count(*)) over() as total_singup_users,
      count(*) :: float / sum(count(*)) over() as pct_users_age_range
from signups
group by age_range
order by age_range




#

with total as (
  select platform, age_range, download_ts, s.user_id,
  count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
group by platform, age_range, download_ts, s.user_id
),


driver_acceptance as ( 
select user_id, count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
group by user_id
),

user_ride_status as ( 
select  user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 ),


payment as ( 
  select user_id, count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
where charge_status = 'Approved'
group by user_id
), 

review as ( 
  select user_id, count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
where charge_status = 'Approved'
group by user_id
  ),

funnel_stage as (
  select  user_id,
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select user_id,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select user_id,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select user_id,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select user_id,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  group by user_id
  
  union
  
	select user_id,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  union 
  
  select user_id,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select funnel_stage.*,platform, age_range, download_ts 
from funnel_stage
left join total
	using(user_id)
order by funnel_step


#

with total as (
  select platform, age_range, download_ts, s.user_id,
  count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
group by platform, age_range, download_ts, s.user_id
),


driver_acceptance as ( 
select user_id, count(distinct user_id) as total_users_driver_accepted
from ride_requests
where driver_id is not NULL
group by user_id
),

user_ride_status as ( 
select  user_id,
	max (case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
group by user_id
 ),


payment as ( 
  select user_id, count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
where charge_status = 'Approved'
group by user_id
), 

review as ( 
  select user_id, count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
where charge_status = 'Approved'
group by user_id
  ),

funnel_stage as (
  select  user_id,
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select user_id,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select user_id,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select user_id,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select user_id,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  group by user_id
  
  union
  
	select user_id,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  union 
  
  select user_id,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select funnel_stage.*,user_id , app_downloads.platform, signups.age_range, app_downloads.download_ts
from funnel_stage
left join total
	using(user_id)
left join signups
	using(user_id)
left join app_downloads
	on app_downloads.app_download_key = signups.session_id
order by funnel_step


27.add platform and 21 rows

with total as (
  select platform, count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
  group by platform
),


driver_acceptance as (
select platform, count(distinct user_id) as total_users_driver_accepted
from ride_requests
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where driver_id is not NULL
group by platform
  
),

user_ride_status as (
select user_id,platform,
	sum(case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
group by user_id ,platform
 ),


payment as (
  select  platform, count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where charge_status = 'Approved'
group by platform
), 

review as (
  select platform, count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where charge_status = 'Approved'
group by platform
  ),

funnel_stage as (
  select  platform,
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select platform,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select platform,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select platform,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select platform,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  group by platform
  
  union
  
	select platform,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  union 
  
  select platform,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select funnel_step, platform,  funnel_name, value as user_count
from funnel_stage
order by funnel_step


28.platform, age_range with 114 rows

with total as (
  select platform, age_range, count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
  group by platform, age_range
),


driver_acceptance as (
select platform, age_range, count(distinct user_id) as total_users_driver_accepted
from ride_requests
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where driver_id is not NULL
group by platform, age_range
  
),

user_ride_status as (
select user_id,platform, age_range,
	sum(case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
group by user_id ,platform, age_range
 ),


payment as (
  select  platform, age_range, count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where charge_status = 'Approved'
group by platform, age_range
), 

review as (
  select platform, age_range, count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where charge_status = 'Approved'
group by platform, age_range
  ),

funnel_stage as (
  select  platform, age_range,
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select platform, age_range,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select platform,age_range,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select platform,age_range,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select platform,age_range,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  group by platform, age_range
  
  union
  
	select platform,age_range,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  
  union 
  
  select platform,age_range,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select funnel_step, platform, age_range, funnel_name, value as user_count
from funnel_stage
order by funnel_step


29.100K rows

with total as (
  select platform, age_range,download_ts, count(distinct app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
  group by platform, age_range,download_ts
),


driver_acceptance as (
select platform, age_range,download_ts, count(distinct user_id) as total_users_driver_accepted
from ride_requests
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where driver_id is not NULL
group by platform, age_range,download_ts
  
),

user_ride_status as (
select user_id,platform, age_range,download_ts,
	sum(case when dropoff_ts is not null
       then 1
       else 0
       end) as user_completed
from ride_requests
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
group by user_id ,platform, age_range,download_ts
 ),


payment as (
  select  platform, age_range,download_ts, count(distinct user_id) as payment_approved
from ride_requests
join transactions
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where charge_status = 'Approved'
group by platform, age_range,download_ts
), 

review as (
  select platform, age_range ,download_ts, count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where charge_status = 'Approved'
group by platform, age_range,download_ts
  ),

funnel_stage as (
  select  platform, age_range,download_ts,
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select platform, age_range,download_ts,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select platform,age_range,download_ts,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select platform,age_range,download_ts,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select platform,age_range,download_ts,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  group by platform, age_range,download_ts
  
  union
  
	select platform,age_range,download_ts,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  
  union 
  
  select platform,age_range,download_ts,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select funnel_step, funnel_name, platform, age_range, value as user_count, download_ts
from funnel_stage
group by platform, age_range,download_ts, funnel_step, funnel_name,  user_count
order by funnel_step


 30.Metrocar

select  platform, age_range,download_ts,
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 count(distinct app_download_key) as value
from metrocar
group by platform, age_range,download_ts

  union 
  
select platform, age_range,download_ts,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	count(distinct user_id) as value
from metrocar
group by platform, age_range,download_ts

  union
  
select platform,age_range,download_ts,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	count(distinct user_id) as value
from metrocar
group by platform, age_range,download_ts

  union
  
select platform,age_range,download_ts,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	count(distinct user_id) as value
from metrocar
where driver_id is not NULL
group by platform, age_range,download_ts

  union
  
select platform,age_range,download_ts,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(case when dropoff_ts is not null
       then 1
       else 0
       end) as value
from metrocar
group by platform, age_range,download_ts

  union
  
select platform,age_range,download_ts,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	count(distinct user_id) as value
from metrocar
where charge_status = 'Approved'
group by platform, age_range,download_ts

  union 
  
select platform,age_range,download_ts,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	count(distinct user_id) as value
from metrocar
where review is not null
group by platform, age_range,download_ts


31. 30K rows

with total as (
  select ad.platform, s.age_range,date_trunc('day', ad.download_ts) as download_date, count(distinct ad.app_download_key) as total_users_dowanloded_app,
  count(distinct s.user_id) as total_users_signed_up, 
	count(distinct r.user_id) as total_users_ride_requested
from app_downloads ad  
left join signups s
	on ad.app_download_key = s.session_id
left join ride_requests r
  using(user_id)
  group by platform, age_range,download_date
),


driver_acceptance as (
select platform, age_range,date_trunc('day', a.download_ts) as download_date, count(distinct user_id) as total_users_driver_accepted
from ride_requests
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where driver_id is not NULL
group by platform, age_range,download_date
  
),

user_ride_status as (
select platform, age_range,date_trunc('day', a.download_ts) as download_date,
	COUNT(DISTINCT r.user_id) AS  user_completed
from ride_requests r
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
WHERE
        r.dropoff_ts IS NOT NULL
group by platform, age_range,download_date
 ),


payment as (
  select  platform, age_range,date_trunc('day', a.download_ts) as download_date, count(distinct t.ride_id) as payment_approved
from transactions t 
join ride_requests
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where charge_status = 'Approved'
group by platform, age_range,download_date
), 

review as (
  select platform, age_range ,date_trunc('day', a.download_ts) as download_date, count(distinct user_id) as total_user_review
from reviews
join transactions
	using(ride_id)
left join signups s
  using(user_id)
left join app_downloads a
  on s.session_id = a.app_download_key
where review is not null
group by platform, age_range,download_date
  ),

funnel_stage as (
  select  platform, age_range,download_date,
  	1 as funnel_step,
 	 'downloaded_app' as funnel_name,
 	 total_users_dowanloded_app as value
  from total
  
  union 
  
  
  select platform, age_range,download_date,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from total
  
  union
  
  select platform,age_range,download_date,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from total
  
  union
  
  select platform,age_range,download_date,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from driver_acceptance
  
  union
  
  select platform,age_range,download_date,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from user_ride_status
  group by platform, age_range,download_date
  
  union
  
	select platform,age_range,download_date,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from payment
  
  
  union 
  
  select platform,age_range,download_date,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from review
  )

select funnel_step, funnel_name, platform, age_range, value as user_count, 
 TO_CHAR(download_date::timestamp, 'YYYY-MM-DD') AS download_date
from funnel_stage
order by funnel_step




32. 30K rows 
with total as (
  select 
  	ad.platform, 
  	s.age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') AS download_date, 
  	count(distinct ad.app_download_key) as total_users_dowanloded_app,
  	count(distinct s.user_id) as total_users_signed_up, 
		count(distinct r.user_id) as total_users_ride_requested
	from 
  	app_downloads ad  
	left join 
  	signups s
			on ad.app_download_key = s.session_id
	left join 
  	ride_requests r
  		using(user_id)
  group by 
  	platform, age_range,download_date
),


driver_acceptance as (
	select 
  	platform, 
  	age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date, 
  	count(distinct user_id) as total_users_driver_accepted
	from 
  	ride_requests
	left join 
  	signups s
 		 	using(user_id)
	left join
  	app_downloads a
 		 on s.session_id = a.app_download_key
where
  	driver_id is not NULL
group by 
  	platform, age_range,download_date
  
),

user_ride_status as (
	select
  	platform, 
  	age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date,
		COUNT(DISTINCT r.user_id) AS  user_completed
	from 
  	ride_requests r
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
WHERE
  	r.dropoff_ts IS NOT NULL
group by
  	platform, age_range,download_date
 ),


payment as (
  select  
  	platform,
  	age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date, 
  	count(distinct t.ride_id) as payment_approved
	from
  	transactions t 
	join 
  	ride_requests
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
where	
  charge_status = 'Approved'
group by platform, age_range,download_date
), 

review as (
  select 
  	platform, 
  	age_range ,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date,
  	count(distinct user_id) as total_user_review
	from 
  	reviews
	join 
  	transactions
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
  		on s.session_id = a.app_download_key
	where 
  	review is not null
	group by 
  	platform, age_range,download_date
  ),

funnel_stage as (
  select  
  	platform, 
  	age_range,
  	download_date,
  	1 as funnel_step,
 	 	'downloaded_app' as funnel_name,
 	 	total_users_dowanloded_app as value
  from 
  	total
  
  union 
  
  select 
  	platform, 
  	age_range,
  	download_date,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value
  from 
  	total
  
  union
  
  select 
  	platform,
  	age_range,
  	download_date,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value
  from 
  	total
  
  union
  
  select 
  	platform,
  	age_range,
  	download_date,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value
  from
  	driver_acceptance
  
  union
  
  select 
  	platform,
  	age_range,
  	download_date,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value
  from 
  	user_ride_status
  group by
  	platform, age_range,download_date
  
  union
  
	select 
  	platform,
  	age_range,
  	download_date,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value
  from 
  	payment
  
  union 
  
  select 
  	platform,
  	age_range,
  	download_date,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value
  from 
  	review
  )

select 
	funnel_step, 
  funnel_name, 
  platform, 
  age_range, 
  value as user_count,
  download_date
from 
	funnel_stage
order by 
	funnel_step



32. add ride to user

	with total as (
  select 
  	ad.platform,  
    count(distinct ad.app_download_key) as total_users_dowanloded_app,
  	count(distinct s.user_id) as total_users_signed_up,
  	count(distinct r.user_id) as total_users_ride_requested,
    count(distinct r.ride_id) as total_ride_requested
	from 
  	app_downloads ad  
	left join 
  	signups s
			on ad.app_download_key = s.session_id
	left join 
  	ride_requests r
  		using(user_id)
  group by 
  	platform
),


driver_acceptance as (
	select 
  	platform,  
  	count(distinct user_id) as total_users_driver_accepted,
  	count(distinct ride_id) as total_ride_driver_accepted
	from 
  	ride_requests
	left join 
  	signups s
 		 	using(user_id)
	left join
  	app_downloads a
 		 on s.session_id = a.app_download_key
where
  	driver_id is not NULL
group by 
  	platform
  
),

user_ride_status as (
	select
  	platform, 
		COUNT(DISTINCT r.user_id) AS  user_completed,
  	COUNT(DISTINCT r.ride_id) AS  ride_completed
	from 
  	ride_requests r
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
WHERE
  	r.dropoff_ts IS NOT NULL
group by
  	platform
 ),


payment as (
  select  
  	platform, 
  	count(distinct s.user_id) as payment_approved,
  	count(distinct r.ride_id) as payment_approved_ride
	from
  	ride_requests r  
	join 
  	transactions t
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
where	
  charge_status = 'Approved'
group by platform
), 

review as (
  select 
  	platform, 
  	count(distinct user_id) as total_user_review,
  	count(distinct ride_id) as total_ride_review
	from 
  	reviews
	join 
  	transactions
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
  		on s.session_id = a.app_download_key
	where 
  	review is not null
	group by 
  	platform
  ),

funnel_stage as (
  select  
  	platform, 
  	1 as funnel_step,
 	 	'downloaded_app' as funnel_name,
 	 	total_users_dowanloded_app as value,
  	0 as ride_count
  from 
  	total
  
  union 
  
  select 
  	platform, 
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value,
  	0 as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value,
  	total_ride_requested as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value,
  	total_ride_driver_accepted as ride_count
  from
  	driver_acceptance
  
  union
  
  select 
  	platform,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value,
  	ride_completed as ride_count
  from 
  	user_ride_status
  group by
  	platform, ride_completed
  
  union
  
	select 
  	platform,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value,
  	payment_approved_ride as ride_count
  from 
  	payment
  
  union 
  
  select 
  	platform,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value,
  	total_ride_review as ride_count
  from 
  	review
  )

select 
	funnel_step, 
  funnel_name, 
  platform,  
  value as user_count,
	ride_count
from 
	funnel_stage
order by 
	funnel_step


33. users+rides

	with total as (
  select 
  	ad.platform , 
  	s.age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') AS download_date, 
    count(distinct ad.app_download_key) as total_users_dowanloded_app,
  	count(distinct s.user_id) as total_users_signed_up,
  	count(distinct r.user_id) as total_users_ride_requested,
    count(distinct r.ride_id) as total_ride_requested
	from 
  	app_downloads ad  
	left join 
  	signups s
			on ad.app_download_key = s.session_id
	left join 
  	ride_requests r
  		using(user_id)
  group by 
  	platform, age_range, download_date
),


driver_acceptance as (
	select 
  	platform,  
    age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date,
  	count(distinct user_id) as total_users_driver_accepted,
  	count(distinct ride_id) as total_ride_driver_accepted
	from 
  	ride_requests
	left join 
  	signups s
 		 	using(user_id)
	left join
  	app_downloads a
 		 on s.session_id = a.app_download_key
where
  	driver_id is not NULL
group by 
  	platform, age_range,download_date
  
),

user_ride_status as (
	select
  	platform, 
    age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date,
		COUNT(DISTINCT r.user_id) AS  user_completed,
  	COUNT(DISTINCT r.ride_id) AS  ride_completed
	from 
  	ride_requests r
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
WHERE
  	r.dropoff_ts IS NOT NULL
group by
  	platform, age_range,download_date
 ),


payment as (
  select  
  	platform, 
    age_range,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date,
  	count(distinct s.user_id) as payment_approved,
  	count(distinct r.ride_id) as payment_approved_ride
	from
  	ride_requests r  
	join 
  	transactions t
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
where	
  charge_status = 'Approved'
group by platform, age_range,download_date
), 

review as (
  select 
  	platform, 
    age_range ,
  	TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD') as download_date,
  	count(distinct user_id) as total_user_review,
  	count(distinct ride_id) as total_ride_review
	from 
  	reviews
	join 
  	transactions
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
  		on s.session_id = a.app_download_key
	where 
  	review is not null
	group by 
  	platform, age_range,download_date
  ),

funnel_stage as (
  select  
  	platform, 
    age_range,
  	download_date,
  	1 as funnel_step,
 	 	'downloaded_app' as funnel_name,
 	 	total_users_dowanloded_app as value,
  	0 as ride_count
  from 
  	total
  
  union 
  
  select 
  	platform,
    age_range,
  	download_date,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value,
  	0 as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value,
  	total_ride_requested as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value,
  	total_ride_driver_accepted as ride_count
  from
  	driver_acceptance
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value,
  	ride_completed as ride_count
  from 
  	user_ride_status
  group by
  	platform,age_range,download_date, ride_completed
  
  union
  
	select 
  	platform,
    age_range,
  	download_date,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value,
  	payment_approved_ride as ride_count
  from 
  	payment
  
  union 
  
  select 
  	platform,
    age_range,
  	download_date,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value,
  	total_ride_review as ride_count
  from 
  	review
  )

select 
	funnel_step, 
  funnel_name, 
  platform,  
  age_range,
  download_date,
  value as user_count,
	ride_count
from 
	funnel_stage
order by 
	funnel_step


33. date(download_ts ) == TO_CHAR(download_ts::timestamp, 'YYYY-MM-DD')

	with total as (
  select 
  	ad.platform , 
  	s.age_range,
  	date(download_ts ) AS download_date, 
    count(distinct ad.app_download_key) as total_users_dowanloded_app,
  	count(distinct s.user_id) as total_users_signed_up,
  	count(distinct r.user_id) as total_users_ride_requested,
    count(distinct r.ride_id) as total_ride_requested
	from 
  	app_downloads ad  
	left join 
  	signups s
			on ad.app_download_key = s.session_id
	left join 
  	ride_requests r
  		using(user_id)
  group by 
  	platform, age_range, download_date
),


driver_acceptance as (
	select 
  	platform,  
    age_range,
  	date(download_ts ) as download_date,
  	count(distinct user_id) as total_users_driver_accepted,
  	count(distinct ride_id) as total_ride_driver_accepted
	from 
  	ride_requests
	left join 
  	signups s
 		 	using(user_id)
	left join
  	app_downloads a
 		 on s.session_id = a.app_download_key
where
  	driver_id is not NULL
group by 
  	platform, age_range,download_date
  
),

user_ride_status as (
	select
  	platform, 
    age_range,
  	date(download_ts ) as download_date,
		COUNT(DISTINCT r.user_id) AS  user_completed,
  	COUNT(DISTINCT r.ride_id) AS  ride_completed
	from 
  	ride_requests r
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
WHERE
  	r.dropoff_ts IS NOT NULL
group by
  	platform, age_range,download_date
 ),


payment as (
  select  
  	platform, 
    age_range,
  	date(download_ts ) as download_date,
  	count(distinct s.user_id) as payment_approved,
  	count(distinct r.ride_id) as payment_approved_ride
	from
  	ride_requests r  
	join 
  	transactions t
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
where	
  charge_status = 'Approved'
group by platform, age_range,download_date
), 

review as (
  select 
  	platform, 
    age_range ,
  	date(download_ts ) as download_date,
  	count(distinct user_id) as total_user_review,
  	count(distinct ride_id) as total_ride_review
	from 
  	reviews
	join 
  	transactions
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
  		on s.session_id = a.app_download_key
	where 
  	review is not null
	group by 
  	platform, age_range,download_date
  ),

funnel_stage as (
  select  
  	platform, 
    age_range,
  	download_date,
  	1 as funnel_step,
 	 	'downloaded_app' as funnel_name,
 	 	total_users_dowanloded_app as value,
  	0 as ride_count
  from 
  	total
  
  union 
  
  select 
  	platform,
    age_range,
  	download_date,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value,
  	0 as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value,
  	total_ride_requested as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value,
  	total_ride_driver_accepted as ride_count
  from
  	driver_acceptance
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value,
  	ride_completed as ride_count
  from 
  	user_ride_status
  group by
  	platform,age_range,download_date, ride_completed
  
  union
  
	select 
  	platform,
    age_range,
  	download_date,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value,
  	payment_approved_ride as ride_count
  from 
  	payment
  
  union 
  
  select 
  	platform,
    age_range,
  	download_date,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value,
  	total_ride_review as ride_count
  from 
  	review
  )

select 
	funnel_step, 
  funnel_name, 
  platform,  
  age_range,
  download_date,
  value as user_count,
	ride_count
from 
	funnel_stage
order by 
	funnel_step


34. 

SELECT
    DATE(request_ts) AS request_day,
    COUNT(*) AS request_count
FROM ride_requests
WHERE request_ts >= '2021-01-01 00:00:00' AND request_ts < '2022-01-01 00:00:00'
GROUP BY request_day
ORDER BY request_count DESC
LIMIT 30



35. user+ride+pickup_time

	with total as (
  select 
  	ad.platform , 
  	s.age_range,
  	date(download_ts ) AS download_date, 
    date_trunc('hour', min(pickup_ts)) as pickup_time,
    count(distinct ad.app_download_key) as total_users_dowanloded_app,
  	count(distinct s.user_id) as total_users_signed_up,
  	count(distinct r.user_id) as total_users_ride_requested,
    count(distinct r.ride_id) as total_ride_requested
	from 
  	app_downloads ad  
	left join 
  	signups s
			on ad.app_download_key = s.session_id
	left join 
  	ride_requests r
  		using(user_id)
  group by 
  	platform, age_range, download_date
),


driver_acceptance as (
	select 
  	platform,  
    age_range,
  	date(download_ts ) as download_date,
  date_trunc('hour', min(pickup_ts)) as pickup_time,
  	count(distinct user_id) as total_users_driver_accepted,
  	count(distinct ride_id) as total_ride_driver_accepted
	from 
  	ride_requests
	left join 
  	signups s
 		 	using(user_id)
	left join
  	app_downloads a
 		 on s.session_id = a.app_download_key
where
  	driver_id is not NULL
group by 
  	platform, age_range,download_date
  
),

user_ride_status as (
	select
  	platform, 
    age_range,
  	date(download_ts ) as download_date,
  date_trunc('hour', min(pickup_ts)) as pickup_time,
		COUNT(DISTINCT r.user_id) AS  user_completed,
  	COUNT(DISTINCT r.ride_id) AS  ride_completed
	from 
  	ride_requests r
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
WHERE
  	r.dropoff_ts IS NOT NULL
group by
  	platform, age_range,download_date
 ),


payment as (
  select  
  	platform, 
    age_range,
  	date(download_ts ) as download_date,
  date_trunc('hour', min(pickup_ts)) as pickup_time,
  	count(distinct s.user_id) as payment_approved,
  	count(distinct r.ride_id) as payment_approved_ride
	from
  	ride_requests r  
	join 
  	transactions t
			using(ride_id)
	left join 
  	signups s
  		using(user_id)
	left join 
  	app_downloads a
 		 on s.session_id = a.app_download_key
where	
  charge_status = 'Approved'
group by platform, age_range,download_date
), 

review as (
SELECT 
    platform, 
    age_range,
    date(download_ts) as download_date,
    date_trunc('hour', min(pickup_ts)) as pickup_time,
    COUNT(DISTINCT reviews.user_id) as total_user_review,
    COUNT(DISTINCT reviews.ride_id) as total_ride_review
FROM 
    reviews
JOIN ride_requests r
    USING(user_id)
LEFT JOIN signups s
    USING(user_id)
LEFT JOIN app_downloads a
    ON s.session_id = a.app_download_key
WHERE 
    review IS NOT NULL
GROUP BY 
    platform, age_range, download_date
  ),

funnel_stage as (
  select  
  	platform, 
    age_range,
  	download_date,
    pickup_time,
  	1 as funnel_step,
 	 	'downloaded_app' as funnel_name,
 	 	total_users_dowanloded_app as value,
  	0 as ride_count
  from 
  	total
  
  union 
  
  select 
  	platform,
    age_range,
  	download_date,
 	  pickup_time,
  	2 as funnel_step,
  	'signups' as funnel_name,
  	total_users_signed_up as value,
  	0 as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
    pickup_time,
  	3 as funnel_step,
  	'ride_requested' as funnel_name,
  	total_users_ride_requested as value,
  	total_ride_requested as ride_count
  from 
  	total
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
    pickup_time,
  	4 as funnel_step,
  	'driver_accepted' as funnel_name,
  	total_users_driver_accepted as value,
  	total_ride_driver_accepted as ride_count
  from
  	driver_acceptance
  
  union
  
  select 
  	platform,
    age_range,
  	download_date,
    pickup_time,
  	5 as funnel_step,
  	'user_completed' as funnel_name,
  	sum(user_completed) as value,
  	ride_completed as ride_count
  from 
  	user_ride_status
  group by
  	platform,age_range,download_date, ride_completed, pickup_time
  
  union
  
	select 
  	platform,
    age_range,
  	download_date,
    pickup_time,
  	6 as funnel_step,
  	'payment_approved' as funnel_name,
  	payment_approved as value,
  	payment_approved_ride as ride_count
  from 
  	payment
  
  union 
  
  select 
  	platform,
    age_range,
  	download_date,
    pickup_time,
  	7 as funnel_step,
  	'user_review' as funnel_name,
  	total_user_review as value,
  	total_ride_review as ride_count
  from 
  	review
  )

SELECT 
    funnel_step, 
    funnel_name, 
    platform,  
    age_range,
    download_date,
		pickup_time,
    value as user_count,
    ride_count
FROM 
    funnel_stage
ORDER BY 
    funnel_step



36. total_ride_request vs ride request per doanload app

with  app_download_count as (    SELECT platform, COUNT(app_download_key) AS total_download_app
    FROM app_downloads
    GROUP BY platform),
   ride_request_count as (  SELECT platform, COUNT(rr.ride_id) AS total_ride_requests
    FROM ride_requests rr
    LEFT JOIN signups s ON rr.user_id = s.user_id
    LEFT JOIN app_downloads ad ON s.session_id = ad.app_download_key
    GROUP BY platform)


SELECT
    app_download_count.platform,
    app_download_count.total_download_app,
    ride_request_count.total_ride_requests,
    ROUND(CAST(ride_request_count.total_ride_requests AS NUMERIC) / app_download_count.total_download_app, 2) AS Ride_Requests_per_Downloaded_App
FROM  app_download_count
JOIN ride_request_count
ON app_download_count.platform = ride_request_count.platform;





