set serveroutput on;
set verify off;

drop table TestData cascade constraints;
drop table Train cascade constraints;



create table Train(
	train_id int,
	country varchar2(20),
	city varchar2(20),
	sulfur_dixd_lvl number,
	nitro_oxid_lvl number,
	ph_lvl number,
	time_stamp date,
	u_id int,
	primary key (train_id),
	foreign key (u_id) references Users(u_id));

create table TestData(
	test_id int,
	country varchar2(20),
	city varchar2(20),
	sulfur_dixd_lvl number,
	nitro_oxid_lvl number,
	ph_lvl number,
	time_stamp date,
	u_id int,
	foreign key (u_id) references Users(u_id));

commit;