set serveroutput on;

set verify off;

create or replace view clus_1(ph_view) as 
select t.ph_lvl from ((select train_id,cluster_num from TempTrain) tt inner join (select train_id,ph_lvl from train) t on tt.train_id = t.train_id ) where cluster_num = 1;
	

create or replace view clus_2(ph_view) as 
select t.ph_lvl from ((select train_id,cluster_num from TempTrain) tt inner join (select train_id,ph_lvl from train) t on tt.train_id = t.train_id ) where cluster_num = 2;

	
create or replace function clacDistFromCen
	(
		cenX in CentroidsTable.sulfur_dixd_lvl%type,
		cenY in CentroidsTable.nitro_oxid_lvl%type,
		tarX in TempTrain.dist_cen1%type,
		tarY in	TempTrain.dist_cen2%type
	)
	return number
	is
	
	res number:=0;
	
	begin
			res := SQRT(((cenX-tarX)*(cenX-tarX))+((cenY-tarY)*(cenY-tarY)));

		return res;
end clacDistFromCen;
/

create or replace function getMin(c1 in number, c2 in number)
	return number
	is
	res number := 0;
	begin 
		
		if c1>=c2 then
			res := 2;
		else 
			res := 1;
		end if;
	
	return res;
	
end getMin;
/

create or replace function pred(so2 in number, nitro in number)
	return int
	is
		
		cenX CentroidsTable.sulfur_dixd_lvl%type;
		cenY CentroidsTable.nitro_oxid_lvl%type;
		tarX TempTrain.dist_cen1%type;
		tarY TempTrain.dist_cen2%type;
		
		res1 int;
		res2 int;
		
	begin 
		
		tarX := so2;
		tarY := nitro;
	
		select sulfur_dixd_lvl,nitro_oxid_lvl into cenX,cenY from CentroidsTable where cen_id = 1;
		
		res1 := utils.clacDistFromCen(cenX,cenY,tarX,tarY);
			
		select sulfur_dixd_lvl,nitro_oxid_lvl into cenX,cenY from CentroidsTable where cen_id = 2;

		res2 := utils.clacDistFromCen(cenX,cenY,tarX,tarY);
			
		return utils.getMin(res1,res2);
	
			
end pred;  
/

create or replace function ph_pred(c in int)
return number
is
	
	pred_val number :=0 ;
	cnt int := 0 ;
begin
	
	if c = 1 then
		
		for d in (select * from clus_1)
		loop
			
			pred_val := pred_val + d.ph_view;
			cnt := cnt +1;
		
		end loop;
	
	elsif c = 2 then
		for d in (select * from clus_2)
		loop
			
			pred_val := pred_val + d.ph_view;
			cnt := cnt +1;
		end loop;
	
	else 
		dbms_output.put_line('Invalid Cluster');
	end if;
		
		pred_val := pred_val/cnt;
	return pred_val;

end ph_pred;
/

declare 

	so2 number := &so2;
	nitro number := &nitro;
	cl int;
	ph number;

begin
	
	cl := pred(so2,nitro);
	ph := ph_pred(cl);
	
	dbms_output.put_line('Predicted Cluster:'|| cl || ', Predicted PH:'|| ph);
	
	if ph<5 then
		dbms_output.put_line('Prediction of Acid rain: Yes');
	else
		dbms_output.put_line('Prediction of Acid rain: No');
	end if;
	
	

end;
/


	