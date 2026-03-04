-- policy_transaction as pt, claim_transaction as ct, vehicle_master as vm

-- Q1 
select 
    day_diff,
    count(*) as num_claims
from (
    select 
        datediff(day, pt.policy_effective_date, ct.claim_accident_date) as day_diff
    from policy_transaction pt
    join claim_transaction ct 
        on pt.policy_no = ct.policy_no
) t
group by day_diff
order by day_diff;


-- Q2 
with premium_brand as (
    select 
    vm.vehicle_brand,
    sum(pt.net_premium) as total_net_premium
    from vehicle_master vm
    join policy_transaction pt on vm.vehicle_id = pt.vehicle_id
    group by vm.vehicle_brand
)
with ranked_premium_brands as (
    select
    vehicle_brand,
    total_net_premium,
    row_number() over (order by total_net_premium desc) as rn
    from premium_brand
)

select 
(sum(case when rn <= 10 then total_net_premium else 0 end) / sum(total_net_premium)) * 100 as top_10_brands_percentage,
(sum(case when rn > 10 then total_net_premium else 0 end) / sum(total_net_premium)) * 100 as other_brands_percentage
from ranked_premium_brands

    
-- Q3
-- loss ratio= (sum(claim_amount) / sum(earned_premium)) * 100 
with loss_ratios as (
    select 
        vm.vehicle_brand,
        vm.vehicle_model,
        year(ct.claim_accident_date) as claim_year,
        sum(ct.claim_amount) as total_claim_amount,
        sum(pt.earned_premium) as total_earned_premium,
        (sum(ct.claim_amount) * 100.0 / sum(pt.earned_premium)) as loss_ratio
    from vehicle_master vm
    join policy_transaction pt 
        on vm.vehicle_id = pt.vehicle_id
    join claim_transaction ct 
        on pt.policy_no = ct.policy_no
    where year(ct.claim_accident_date) in (2023, 2024)
      and year(pt.expiry_date) > year(ct.claim_accident_date)
    group by vm.vehicle_brand, vm.vehicle_model, year(ct.claim_accident_date)
)
select 
    lr2024.vehicle_brand,
    lr2024.vehicle_model,
    lr2024.loss_ratio - lr2023.loss_ratio as loss_ratio_diff
from loss_ratios lr2023
join loss_ratios lr2024
    on lr2023.vehicle_brand = lr2024.vehicle_brand
   and lr2023.vehicle_model = lr2024.vehicle_model
   and lr2023.claim_year = 2023
   and lr2024.claim_year = 2024
where lr2024.loss_ratio > lr2023.loss_ratio
order by loss_ratio_diff desc
limit 3;

-- Q4
with loss_ratio_per_policy_per_agent as (
    select
        pt.policy_no,
        pt.agent_code,
        sum(ct.claim_amount) as total_claim_amount,
        sum(pt.earned_premium) as total_earned_premium,
        (sum(ct.claim_amount) * 100.0 / nullif(sum(pt.earned_premium),0)) as loss_ratio
    from policy_transaction pt
    join claim_transaction ct 
        on pt.policy_no = ct.policy_no
    where pt.expiry_date between current_date() and dateadd(day, 60, current_date())
    group by pt.policy_no, pt.agent_code
)
select 
    agent_code,
    case 
        when loss_ratio < 50 then 'Good'
        when loss_ratio between 50 and 80 then 'Moderate'
        else 'Bad'
    end as risk_segment,
    count(*) as num_policies
from loss_ratio_per_policy_per_agent
group by agent_code,
         case 
            when loss_ratio < 50 then 'Good'
            when loss_ratio between 50 and 80 then 'Moderate'
            else 'Bad'
         end
order by agent_code, risk_segment;

-- Q5

select
    vm.vehicle_identification_no,
    pt.policy_no,
    case
        when lag(pt.expiry_date) over (
                 partition by vm.vehicle_identification_no 
                 order by pt.issued_date
             ) is null 
            then 'New'
        when datediff(
                 day, 
                 lag(pt.expiry_date) over (
                     partition by vm.vehicle_identification_no 
                     order by pt.issued_date
                 ), 
                 pt.issued_date
             ) <= 30 
            then 'Renewal'
        else 'New'
    end as policy_type
from policy_transaction pt
join vehicle_master vm 
    on pt.vehicle_id = vm.vehicle_id
order by vm.vehicle_identification_no, pt.policy_no;
