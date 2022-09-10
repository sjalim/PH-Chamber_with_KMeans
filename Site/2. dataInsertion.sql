set serveroutput on;
set verify off;

insert into Users(u_id,name,city) values(1,'Alim','Dhaka');
insert into Users(u_id,name,city) values(2,'Alim1','Dhaka');
insert into Users(u_id,name,city) values(3,'Alim2','Dhaka');
insert into Users(u_id,name,city) values(4,'Alim3','Dhaka');
insert into Users(u_id,name,city) values(5,'Alim4','Dhaka');

insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(1 ,'Dhaka',0.38,0.01,5.088352647583345,'11-Feb-22',2);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(2 ,'Dhaka',0.02,0.51,5.464738839548676,'11-Feb-22',4);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(3 ,'Dhaka',0.94,0.88,4.217728047597984,'11-Feb-22',1);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(4 ,'Dhaka',0.77,0.96,4.302251507753369,'11-Feb-22',2);
insert into Train(train_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(5 ,'Dhaka',0.65,0.84,4.214153039975565,'11-Feb-22',4);


insert into TestData(test_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(1 ,'Dhaka',0.35,0.11,4.088352647583345,'11-Feb-22',2);
insert into TestData(test_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(2 ,'Dhaka',0.12,0.51,5.464738839548676,'11-Feb-22',4);
insert into TestData(test_id,city,sulfur_dixd_lvl,nitro_oxid_lvl,ph_lvl,time_stamp,u_id) values(3 ,'Dhaka',0.9,0.8,4.217728047597984,'11-Feb-22',1);
commit;
