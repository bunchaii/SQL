-- policy_transaction as pt, claim_transaction as ct, vehicle_master as vm

-- Q1 
select 
datediff(day, pt.policy_effective_date, ct.claim_accident_date) as day_diff
, count(*) as num_claims
from policy_transaction pt
join claim_transaction ct on pt.policy_no = ct.policy_no
group by datediff(day, pt.policy_effective_date, ct.claim_accident_date)
order by day_diff

-- Q2 
with net_per_brand as (
    select 
    vm.vehicle_brand,
    sum(pt.net_premium) as total_net_premium
    from vehicle_master vm
    join policy_transaction pt on vm.vehicle_id = pt.vehicle_id
    group by vm.vehicle_brand
),
top10_net_brand as (
    select 
    vehicle_brand, 
    total_net_premium
    from net_per_brand
    order by total_net_premium desc
    limit 10
), 
total_premium as (
    select 
    sum(net_premium) as total_net_premium
    from policy_transaction
),
total_premium_top10 as (
    select 
    sum(total_net_premium) as total_top10_net_premium
    from top10_net_brand
)

Select
(total_top10_net_premium / total_net_premium) * 100 as percentage_top10_net_premium
,(total_net_premium - total_top10_net_premium) / total_net_premium * 100 as percentage_other_brands
from total_premium, total_premium_top10

-- Q3
-- loss ratio= (sum(claim_amount) / sum(earned_premium)) * 100 

with lr_2023 as (
    select 
    vm.vehicle_brand,
    vm.vehicle_model,
    sum(ct.claim_amount) as total_claim_amount,
    sum(pt.earned_premium) as total_earned_premium,
    (sum(ct.claim_amount) / sum(pt.earned_premium)) * 100 as loss_ratio
    from vehicle_master vm
    join policy_transaction pt on vm.vehicle_id = pt.vehicle_id
    join claim_transaction ct on pt.policy_no = ct.policy_no
    where 
    year(ct.claim_accident_date) = 2023
    and year(pt.expiry_date) > 2023
    group by vm.vehicle_brand, vm.vehicle_model
),
lr_2024 as (
    select 
    vm.vehicle_brand,
    vm.vehicle_model,
    sum(ct.claim_amount) as total_claim_amount,
    sum(pt.earned_premium) as total_earned_premium,
    (sum(ct.claim_amount) / sum(pt.earned_premium)) * 100 as loss_ratio
    from vehicle_master vm
    join policy_transaction pt on vm.vehicle_id = pt.vehicle_id
    join claim_transaction ct on pt.policy_no = ct.policy_no
    where 
    year(ct.claim_accident_date) = 2024
    and year(pt.expiry_date) > 2024
    group by vm.vehicle_brand, vm.vehicle_model
)

select 
vehicle_brand, 
vehicle_model, 
lr24.loss_ratio - lr23.loss_ratio as loss_ratio_diff
from lr_2023 lr23
join lr_2024 lr24 
on lr23.vehicle_brand = lr24.vehicle_brand 
and lr23.vehicle_model = lr24.vehicle_model
where 
lr24.loss_ratio > lr23.loss_ratio

order by loss_ratio_diff desc
limit 3

-- Q4

with loss_ratio_per_policy_per_agent as (
    select
    pt.policy_no,
    pt.agent_code,
    sum(ct.claim_amount) as total_claim_amount,
    sum(pt.earned_premium) as total_earned_premium,
    case 
    when (sum(ct.claim_amount) / sum(pt.earned_premium) * 100) < 50 then 'Good'
    when (sum(ct.claim_amount) / sum(pt.earned_premium) * 100) between 50 and 80 then 'Moderate'
    when (sum(ct.claim_amount) / sum(pt.earned_premium) * 100) > 80 then 'Bad'
    end as risk_segment

    from policy_transaction pt
    join claim_transaction ct on pt.policy_no = ct.policy_no
    where pt.expiry_date between current_date() and dateadd(day, 60, current_date())
    group by pt.policy_no,  pt.agent_code
)

select agent_code, risk_segment, count(*) as num_policies
from loss_ratio_per_policy_per_agent
group by agent_code, risk_segment
order by agent_code, risk_segment

-- Q5

with policy_history as (
    select
    vm.vehicle_identification_no,
    pt.policy_no,
    pt.issued_date,
    pt.expiry_date,
    lag(pt.expiry_date) over (partition by vm.vehicle_identification_no order by pt.issued_date) as prev_expiry_date

    from policy_transaction pt
    join vehicle_master vm on pt.vehicle_id = vm.vehicle_id
)
select
vehicle_identification_no,
policy_no,
case
when prev_expiry_date is null then 'New'
when datediff(day, prev_expiry_date, issued_date) <= 30 then 'Renewal'
else 'New'
end as policy_type

from policy_history
order by vehicle_identification_no, policy_no

