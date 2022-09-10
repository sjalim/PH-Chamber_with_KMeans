set serveroutput on;
set verify off;

-- Users Data Local mapping
insert into Users(u_id,name,city) values(1,'Alim','Barisal');
insert into Users(u_id,name,city) values(2,'Alim1','Barisal');
insert into Users(u_id,name,city) values(3,'Alim2','Barisal');
insert into Users(u_id,name,city) values(4,'Alim3','Barisal');
insert into Users(u_id,name,city) values(5,'Alim4','Barisal');

-- Train Data Local mapping
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(1 ,'Barisal',0.21,0.49,5.188321681104128,'11-Feb-22',1);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(2,'Barisal',0.25,0.47,5.448242634464495,'11-Feb-22',3);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(3,'Barisal',0.35,0.50,5.386043242962638,'11-Feb-22',5);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(4,'Barisal',0.85,0.46,4.2120069205880695,'11-Feb-22',1);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(5 ,'Barisal',0.81,0.49,4.287156549116994,'11-Feb-22',3);


insert into TestData(test_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(1,'Barisal',0.32,0.1,4.188321681104128,'11-Feb-22',1);
insert into TestData(test_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(2 ,'Barisal',0.15,0.2,5.448242634464495,'11-Feb-22',3);
insert into TestData(test_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(3 ,'Barisal',0.27,0.45,5.386043242962638,'11-Feb-22',5);



commit;