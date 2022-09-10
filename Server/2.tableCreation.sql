set serveroutput on;
set verify off;

drop table EvaluationTrack cascade constraints;
drop table TestData cascade constraints;
drop table CentroidsTable cascade constraints;
drop table Train cascade constraints;
drop table TempTrain;
drop table Users cascade constraints;



create table Users(
	u_id int,
	name varchar2(20),
	city varchar2(20),
	primary key (u_id)
	);

create table Train(
	train_id int,
	city varchar2(20),
	sulfur_dixd_lvl number,
	nitro_oxid_lvl number,
	ph_lvl number,
	time_stamp date,
	u_id int,
	primary key (train_id),
	foreign key (u_id) references Users(u_id)
	);


create table TempTrain(
	temp_train_id int,
	train_id int,
	dist_cen1 number,
	dist_cen2 number,
	cluster_num int
	);

create table CentroidsTable(
	cen_id int,
	sulfur_dixd_lvl number,
	nitro_oxid_lvl number,
	time_stamp date,
	u_id int,
	foreign key (u_id) references Users(u_id)
	);
	
create table TestData(
	test_id int,
	city varchar2(20),
	sulfur_dixd_lvl number,
	nitro_oxid_lvl number,
	ph_lvl number,
	time_stamp date,
	u_id int,
	foreign key (u_id) references Users(u_id)
	);

create table EvaluationTrack(
	track_id int,
	selected_city_country varchar(20),
	prec number,
	recall number,
	accuracy number,
	f1_score number,
	time_stamp date,
	u_id int,
	foreign key (u_id) references Users(u_id)
	);

commit;