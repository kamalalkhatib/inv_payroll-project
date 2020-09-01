/*This package contains the required pro and fun to retrieve the required data
  and to achieve the required salary calculations*/
create or replace package sal_calc_pkg
is
null_exc exception; 
function tax_calc(p_perid in work_periods.per_id%type) return number;
function allownce_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number;
function deduction_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number;
--This fun returns sum working hours for a specific period.
function hours_sum(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number;
-- This fun returns hourly rate 
function hour_sal(p_empid in emp.emp_id%type)return number;
--This fun calculates sal before any allowences or deductions
function sal_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number;
function emp_title(p_empid in emp.emp_id%type)return number;
--This pro calculates the net sal after taxes, allowences and deductions
procedure sal_net_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type);
-- This pro used to insert all sal details into the required tables
procedure sal_net_insert(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type,p_tax taxes.tax_value%type,
p_allow allowences.all_value%type,p_ded deductions.ded_value%type,p_wsal number,p_netsal number);
--This fun check if emp worked over time 
function hour_overtime_chk(p_hour number) return boolean;
--This function returns number of hours where after that will be over time.
function overtime_edge return number;
--This fun returns the over time hourly sal
function overtime_sal return number;
end;
/
create or replace package body sal_calc_pkg
is
-- This function returns sum of taxes
function tax_calc(p_perid in work_periods.per_id%type) return number
is
v_tax taxes.tax_value%type;
begin
if p_perid is null
then
raise null_exc;
end if;
select sum(tax_value) into v_tax from taxes
where tax_id in (select tax_id from emp_per_taxes where per_id=p_perid);
return v_tax;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
--This function returns allowences for each emp based on specific period
function allownce_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number
is
v_allow allowences.all_value%type;
begin
if (p_perid is null or p_empid is null)
then
raise null_exc;
end if;
select sum(all_value) into v_allow from allowences
where all_id in
    ( select all_id from emp_per_allowences where emp_id=p_empid and per_id=p_perid);
return v_allow;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
--This function returns deductions for each emp based on specific period
function deduction_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number
is
v_ded deductions.ded_value%type;
begin
if (p_perid is null or p_empid is null)
then
raise null_exc;
end if;
select sum(ded_value) into v_ded from deductions
where ded_id in
    ( select ded_id from emp_per_deductions where emp_id=p_empid and per_id=p_perid);
return v_ded;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
--this function returns working hours/emp for a specific period
function hours_sum(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number
is
v_hour number(5,2);
begin
if (p_perid is null or p_empid is null)
then
raise null_exc;
end if;
select sum(time_diff) into v_hour from emp_in_out_time
where emp_id = p_empid and per_id = p_perid;
return v_hour;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
--This function returns the hourly sal for each emp.
function hour_sal(p_empid in emp.emp_id%type)return number
is
v_hsal titles.tit_hsal%type;
v_em_tit titles.tit_id%type;
begin
if p_empid is null then
raise null_exc;
end if;
-- calling this function to return emp title to get the sal/hour
v_em_tit:=emp_title(p_empid);
select tit_hsal into v_hsal from titles
where tit_id = v_em_tit;
return v_hsal;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
--This function checks if emp has worked overtime
function hour_overtime_chk(p_hour number) return boolean
is
v_over_edg default_values.def_value%type;
v_condition boolean;
begin
/*caliing a function to check overtime edge*/
v_over_edg := overtime_edge;
if p_hour is null then
raise null_exc;
end if;
if p_hour > v_over_edg then
v_condition:=true;
else
v_condition:=false;
end if;
return v_condition;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
/*This function returns the value where after that emp considered
  worked overtime */
function overtime_edge return number
is
v_over_edg default_values.def_value%type;
begin
select def_value into v_over_edg from default_values
where
def_id = 1;
return v_over_edg;
exception
when others then
raise;
end;
/*This function returns the ratio of overtime sal /hour */
function overtime_sal return number
is
v_over_equ default_values.def_value%type;
begin
select def_value into v_over_equ from default_values
where
def_id = 2;
return v_over_equ;
exception
when others then
raise;
end;
/* this function calculates emp's sal before taxes,deductions and allowences */
function sal_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)return number
is
v_wsal number(6,2);
v_hsum number(5,2);
v_hsal titles.tit_hsal%type;
v_h_over number(6,2);
v_over_edg number(6,2);
v_over_sal number(6,2);
v_edge_sal number(6,2);
v_overtime_sal default_values.def_value%type;
begin
if (p_perid is null or p_empid is null)
then
raise null_exc;
end if;
-- Returns sum of working hours/period
v_hsum:=hours_sum(p_perid,p_empid);
-- Returns hourly paid.
v_hsal:=hour_sal(p_empid);
if hour_overtime_chk(v_hsum) then
v_over_edg := overtime_edge;
v_overtime_sal := overtime_sal;
--calc overtime hours
v_h_over:=(v_over_edg - v_hsum);
-- calc overtime sal
v_over_sal:=v_h_over * (v_hsal*v_overtime_sal);
--calc regular hours sal
v_edge_sal:= v_over_edg * v_hsal;
-- calc overtime plus regular hours sal
v_wsal:=v_over_sal + v_edge_sal;
else
-- if there was overtime
-- calc the initial sal before taxes,allowences and deductions.
v_wsal:=v_hsum*v_hsal;
end if;
return v_wsal;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
/* This function returns emp's title to find later the hourly sal */
function emp_title(p_empid in emp.emp_id%type)return number
is
v_title titles.tit_id%type;
begin
if p_empid is null then
raise null_exc;
end if;
 select TITLE into v_title from emp
where emp_id=p_empid;
return v_title;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
/* This procedure contains insert statement that insert all the calculated data into
   emp_sal_period after net sal calculation */
procedure sal_net_insert(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type,p_tax taxes.tax_value%type,
p_allow allowences.all_value%type,p_ded deductions.ded_value%type,p_wsal number,p_netsal number)
is
begin
if ( p_perid is null or p_empid is null
  or p_tax is null or p_allow is null
  or p_ded is null or p_wsal is null
  or p_netsal is null) then
  raise null_exc;
end if;
insert into emp_sal_period(per_id,emp_id,tot_taxes,tot_all,tot_ded,w_sal,net_sal)
values(p_perid,p_empid,p_tax,p_allow,p_ded,p_wsal,p_netsal);
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
raise;
end;
/* This procedure calculates the net sal after taxes,deductions and allowences
   then calls the required procedure to insert the data into emp_sal_period to
   keep copy in the database */
procedure sal_net_calc(p_perid in work_periods.per_id%type,p_empid in emp.emp_id%type)
is
v_tax taxes.tax_value%type;
v_allow allowences.all_value%type;
v_ded deductions.ded_value%type;
v_wsal number(6,2);
v_netsal number(6,2);
type t_emp is table of emp%rowtype index by pls_integer;
v_emp t_emp;
cursor c_emp is select * from emp;
type emp_sal_rec is record(
emp_id number(4),work_period number(4),emp_tax number(2,1),emp_all number(2,1),emp_ded number(2,1),week_sal number(6,2),net_sal number(6,2)
);
   type emp_sal_type is table of emp_sal_rec
   index by binary_integer;
   v_emp_sal emp_sal_type;
begin
if (p_perid is null or p_empid is null)
then
raise null_exc;
end if;
open c_emp;
loop
fetch c_emp bulk collect into v_emp limit 100;
exit when v_emp.count=0;
for i in v_emp.first..v_emp.last
loop
v_tax:=tax_calc(p_perid);
v_allow:=allownce_calc(p_perid,v_emp(i).emp_id);
v_ded:=deduction_calc(p_perid,v_emp(i).emp_id);
v_wsal:=sal_calc(p_perid,v_emp(i).emp_id);
v_netsal:=(v_wsal+(v_wsal*v_allow))-((v_wsal*v_tax)+v_wsal*v_ded);
v_emp_sal(i).work_period:=p_perid;
v_emp_sal(i).emp_id:=v_emp(i).emp_id;
v_emp_sal(i).emp_tax:=v_tax;
v_emp_sal(i).emp_all:=v_allow;
v_emp_sal(i).emp_ded :=v_ded;
v_emp_sal(i).week_sal:=v_wsal;
v_emp_sal(i).net_sal:=v_netsal;
end loop;
forall j in v_emp_sal.first..v_emp_sal.last
insert into emp_sal_period(per_id,emp_id,tot_taxes,tot_all,tot_ded,w_sal,net_sal)
values(p_perid,v_emp_sal(j).emp_id,v_emp_sal(j).emp_tax,v_emp_sal(j).emp_all,v_emp_sal(j).emp_ded,v_emp_sal(j).week_sal,v_emp_sal(j).net_sal);
--sal_net_insert(p_perid,v_emp(i).emp_id,v_tax,v_allow,v_ded,v_wsal,v_netsal);
end loop;
close c_emp;
exception
when null_exc then
dbms_output.put_line('null value is not allowed');
when others then
  error_mgr.log_error ('sal calc pro.');
  raise;
end;
end;
/
