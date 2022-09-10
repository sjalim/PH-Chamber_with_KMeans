set serveroutput on;

set verify off;


/* CREATE OR REPLACE FUNCTION NUM_RANDOM(N IN NUMBER)
RETURN NUMBER 
AS 
BEGIN
    RETURN TRUNC (DBMS_RANDOM.VALUE(POWER(10, N - 1), POWER(10, N) - 1));
END NUM_RANDOM;
/ */

create or replace type datasetObj as object(		
	train_id int, 
	sulfur_dixd_lvl number,
	nitro_oxid_lvl number,
	ph_lvl number
);
/


create or replace package utils as

	--return the min distance cluster number
	function getMin(c1 in number, c2 in number)
	return number;
	
	--eulidian distance from center, returns the distance
	function clacDistFromCen
	(
		cenX in CentroidsTable.sulfur_dixd_lvl%type,
		cenY in CentroidsTable.nitro_oxid_lvl%type,
		tarX in TempTrain.dist_cen1%type,
		tarY in	TempTrain.dist_cen2%type
	)
	return number;

end utils;
/

create or replace package body utils as

	function getMin(c1 in number, c2 in number)
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
	
	
	function clacDistFromCen
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
			
			--dbms_output.put_line(res|| ' cenX:'||cenX|| 'tarX:'|| tarX|| 'cenY:'|| cenY|| 'tarY:'|| tarY);
	
		return res;
	end clacDistFromCen;
	
end utils;
/


create or replace package kmeans as


	function userExist(nam in Users.name%type)
	return int;
	
	-- update centroidTable 
	--(so2,nitro)
	procedure updateCentroid; 

	-- define initial centers
	procedure initCentroid;
	
	-- define initial `TempTable`
	procedure initTempTable;
	
	--get train data from server and save into local table `TempTrain` without cluster 
	--(temp_train_data, train_data,cluster_num) cluster_num= null
	procedure getTempTrainData(city in Train.city%type, areaType in int); 
	
	-- copy previously calculated distance in array to stabilitycheck of cluster
	procedure copyPreviousDataClusters;
	
	--if stable returns 0 or 1
	function clusterStabilityCheck
	return int;
	
	--data train cluster define and `TempTrain` table update with cluster	
	procedure fitData;

	
	-- get the pred values
	procedure predTest;
	
	-- store evalution metrices in database
	procedure evaluationMetrics;
	
	-- predict acid rain
	function pred(so2 in number, nitro in number)
	return int;
	
	procedure display;
	
	procedure displayTempTrain;
	
	procedure displayForLocal;
	
	procedure displayForGlobal;
	
	
end kmeans;
/

create or replace package body kmeans as

	type trainData is varray(600) of datasetObj;
	dataset trainData := trainData();
	
	k int := 2;
	u_id int;
	
	type temp_cluster_vals is varray(100) of int;	
	clusters_list temp_cluster_vals := temp_cluster_vals();
	
	acc number;
	prec number;
	re number;
	f1 number;
	
	tp int := 0;
	fp int := 0;
	tn int := 0;
	fn int := 0;
	
	select_city Train.city%type;
	area_type int;
	
	res int;
	
	
	function userExist(nam in Users.name%type)
	return int
	is
	id Users.u_id%type;
	cnt int :=0 ;
	f int := 0;
	begin 
		
		select count(*) into cnt from Users where name = nam;
		
		if cnt = 0 then
			dbms_output.put_line('User donot have access');
		elsif cnt = 1 then
		
			select u_id into id from Users where name = nam;
			
			u_id := id;
			dbms_output.put_line('Welcome to PH Chamber!!');
			f := 1;
		else
			
			dbms_output.put_line('Invalid User');
			
		end if;
		
		return f;
	
	end userExist;
	
	
	procedure evaluationMetrics
	is
		
	time_stamp date;
	id int;
	begin
		
		select CURRENT_TIMESTAMP into time_stamp from dual;
		
		-- dbms_output.put_line('time_stamp'|| time_stamp);
		
		select count(track_id) into id from EvaluationTrack;
		-- dbms_output.put_line('Track len: '|| id);
		
		acc := (tn+tp)/(tn+fp+tp+fn);
		prec := tp/(tp + fp);
		re := tp/(tp + fn);
		f1 := (2* prec * re)/(prec + re);
		
		
		 if id = 0 then
		
		-- dbms_output.put_line('at if');
		
			insert into EvaluationTrack (
			
			track_id ,
			selected_city_country ,
			prec ,
			recall ,
			accuracy ,
			f1_score ,
			time_stamp ,
			u_id 
			)
			values(
				1,
				select_city,
				prec,
				re,
				acc,
				f1,
				time_stamp,
				u_id
			);
			
		else 
			-- dbms_output.put_line('at else');

			insert into EvaluationTrack(
			
				track_id,
				selected_city_country,
				prec,
				recall,
				accuracy,
				f1_score,
				time_stamp,
				u_id
			)
			values(
			
				id+1,
				select_city,
				prec,
				re,
				acc,
				f1,
				time_stamp,
				u_id
			
			);
			
		end if;
		
		 
	
	end evaluationMetrics;
	
	procedure predTest
	is
	
	begin
	
		tp := 0;
		fp := 0;
		tn := 0;
		fn := 0;
		
		-- dbms_output.put_line('area:'|| area_type || ' ' || 'city:'|| select_city);
		
		 if area_type = 0 then -- local
			
			-- dbms_output.put_line('at if');
				
				
				if select_city = 'Barisal' then
						for i in (select sulfur_dixd_lvl, nitro_oxid_lvl,ph_lvl from TestData where city = select_city)
					loop
					
						res := pred(i.sulfur_dixd_lvl, i.nitro_oxid_lvl);
						
						if i.ph_lvl <= 5 then -- AP
							
							-- dbms_output.put_line('At AP');
							
							
							if res <= 5 then -- PP
							
								tp := tp + 1; -- TP
							
							else 				-- PN
								fp := fp + 1; -- FP
							end if;
							
						else -- AN
						
						-- dbms_output.put_line('At AN');

							if res >= 5 then -- PN
								tn := tn + 1; -- TN
							else 				-- PP
								fn := fn + 1; -- FN
							end if;
						
						end if;
						
					end loop;
				elsif select_city = 'Dhaka' then
				
						for i in (select sulfur_dixd_lvl, nitro_oxid_lvl,ph_lvl from TestData@site1 where city = select_city)
					loop
					
						res := pred(i.sulfur_dixd_lvl, i.nitro_oxid_lvl);
						
						if i.ph_lvl <= 5 then -- AP
							
							-- dbms_output.put_line('At AP');
							
							
							if res <= 5 then -- PP
							
								tp := tp + 1; -- TP
							
							else 				-- PN
								fp := fp + 1; -- FP
							end if;
							
						else -- AN
						
						-- dbms_output.put_line('At AN');

							if res >= 5 then -- PN
								tn := tn + 1; -- TN
							else 				-- PP
								fn := fn + 1; -- FN
							end if;
						end if;
					end loop;
				else
					
					dbms_output.put_line('Invalid city in Test data');
				end if;
			
				
		
		elsif area_type = 1 then -- global
			
			-- dbms_output.put_line('at else if');
			
			for i in 
			(
			select sulfur_dixd_lvl, nitro_oxid_lvl,ph_lvl from TestData where city = select_city
			union 
			select sulfur_dixd_lvl, nitro_oxid_lvl,ph_lvl from TestData@site1 where city = select_city
			)
			loop
				
				 if i.ph_lvl <= 5 then -- AP
					
					res := pred(i.sulfur_dixd_lvl, i.nitro_oxid_lvl);
					
					if res <= 5 then -- PP
						tp := tp + 1; -- TP
					else 				-- PN
						fp := fp + 1; -- FP
					end if;
					
				else -- AN
					if res > 5 then -- PN
						tn := tn + 1; -- TN
					else 				-- PP
						fn := fn + 1; -- FN
					end if;
				end if;
			end loop;
		else
		
			dbms_output.put_line('Invalid area Type');
		end if; 
		
		-- dbms_output.put_line('tp:'||tp||' fp:'||fp|| ' tn:'|| tn|| ' fn:'|| fn);
			
	
	end predTest;
	
	
	function pred(so2 in number, nitro in number)
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
		-- dbms_output.put_line('at pred');
		
		
		select sulfur_dixd_lvl,nitro_oxid_lvl into cenX,cenY from CentroidsTable where cen_id = 1;
		
		res1 := utils.clacDistFromCen(cenX,cenY,tarX,tarY);
			
		select sulfur_dixd_lvl,nitro_oxid_lvl into cenX,cenY from CentroidsTable where cen_id = 2;

		res2 := utils.clacDistFromCen(cenX,cenY,tarX,tarY);
			
		return utils.getMin(res1,res2);
	
			
	end pred;  
	
	
	
	function clusterStabilityCheck
	return int
	is 
	
	flag int := 0; -- 1 same cluster_list, 0 not same
	cnt int := 1;
	begin
	
		for i in (select cluster_num from TempTrain)
		loop 
			
			-- dbms_output.put_line('loop check ' || clusters_list(cnt)|| ' '|| i.cluster_num);
			if clusters_list(cnt) != i.cluster_num then
				return flag;
			end if;
			
		cnt := cnt + 1;
		end loop;
		
		flag := 1;
		-- dbms_output.put_line('loop cnt :' || cnt || ' '|| clusters_list.count);
		
		return flag;
		
	end clusterStabilityCheck; 
	
	

	procedure getTempTrainData(city in Train.city%type, areaType in int)
	is 
	dt datasetObj;
	
	begin
				-- dbms_output.put_line('at getTempTrainData');
				
		select_city := city;
		area_type := areaType;
		-- dbms_output.put_line('at proc');
		if areaType = 0 then -- local 
			
			if select_city = 'Barisal' then
				
				for d in (select train_id, sulfur_dixd_lvl, nitro_oxid_lvl, ph_lvl from train where city = city ) loop
				dt := datasetObj(d.train_id, d.sulfur_dixd_lvl, d.nitro_oxid_lvl, d.ph_lvl);
				dataset.extend;
				dataset(dataset.last) := dt;
			end loop;
			
			elsif select_city = 'Dhaka' then
				
				for d in (select train_id, sulfur_dixd_lvl, nitro_oxid_lvl, ph_lvl from train@site1 where city = city ) 
				loop
					dt := datasetObj(d.train_id, d.sulfur_dixd_lvl, d.nitro_oxid_lvl, d.ph_lvl);
					dataset.extend;
					dataset(dataset.last) := dt;
				end loop;
				
				
			else 
			
				dbms_output.put_line('Invalid city! city doesnot exist');
			
			end if;
		
			
		elsif areaType = 1 then -- global
			for d in (
			select train_id, sulfur_dixd_lvl, nitro_oxid_lvl, ph_lvl from train 
			union 
			select train_id, sulfur_dixd_lvl, nitro_oxid_lvl, ph_lvl from train@site1
 
			
			) loop
				dt := datasetObj(d.train_id, d.sulfur_dixd_lvl, d.nitro_oxid_lvl, d.ph_lvl);
				dataset.extend;
				dataset(dataset.last) := dt;
			end loop;
			
		else
			dbms_output.put_line('Invalid param passed to the procedure');
		end if;
		
	end getTempTrainData;
	
	
	 procedure initCentroid
	is
	
	time_stamp date;
	rows_num int;
	already_init exception;
	
	begin
		-- dbms_output.put_line('at initCentroid' || k || u_id);
		
		select count(*) into rows_num from CentroidsTable;
		
		
		if rows_num = 0 then
			select CURRENT_TIMESTAMP into time_stamp from dual;
			
				insert into CentroidsTable(cen_id,sulfur_dixd_lvl,nitro_oxid_lvl,time_stamp,u_id)
								values(1,0.2,0.4,time_stamp,u_id);
			
			
			insert into CentroidsTable(cen_id,sulfur_dixd_lvl,nitro_oxid_lvl,time_stamp,u_id)
								values(2,0.8,0.4,time_stamp,u_id);
		else
			-- dbms_output.put_line('at initCentroid exception');
			raise already_init;
		end if;
		
	exception 
		when already_init then
			dbms_output.put_line('Centroid Table Initialized!');
		
	end initCentroid; 
	
	
	 procedure initTempTable
	is
	
	a CentroidsTable.sulfur_dixd_lvl%type;
	b CentroidsTable.nitro_oxid_lvl%type;
	c number;
	d number;
	res number;
	cnt int := 0;
	ex_init_temp_train exception;
	rows_cnt_temp_train int := 0;
	
	begin
	
		select count(*) into rows_cnt_temp_train from TempTrain;
	
		-- dbms_output.put_line('at initTempTable ');
		
		 if rows_cnt_temp_train = 0 then
			-- dbms_output.put_line('at if ');
		
		 	for j in dataset.first .. dataset.last 
			loop
				
				c := dataset(j).sulfur_dixd_lvl;
				d := dataset(j).nitro_oxid_lvl;
				
				
				cnt := 0;
				for i in (select sulfur_dixd_lvl,nitro_oxid_lvl from CentroidsTable) 
				loop
			
					a := i.sulfur_dixd_lvl;
					b := i.nitro_oxid_lvl;	
				
					res := utils.clacDistFromCen(c,d,a,b);
						
						
						if cnt =0 then
						
							insert into TempTrain(temp_train_id,train_id,dist_cen1,dist_cen2,cluster_num)
									values(j,dataset(j).train_id,res,0,0);
						
						elsif cnt = 1 then
						
							update TempTrain 
							set dist_cen2 = res
							where temp_train_id = j;
							
						end if;
				cnt := cnt + 1;
				
				end loop;

			end loop;
			
		elsif rows_cnt_temp_train > 0 then
		
			raise ex_init_temp_train;
			
		end if; 
		
		
		for i in (select temp_train_id, dist_cen1, dist_cen2 from TempTrain) 
		loop
			
			update TempTrain 
			set cluster_num = utils.getMin(dist_cen1,dist_cen2)
			where temp_train_id = i.temp_train_id;
			
		end loop;
	exception 
		when ex_init_temp_train then
			dbms_output.put_line('Already initialized TempTrain Table!');
	
	end initTempTable;
	
	
	procedure updateCentroid
	is
	
	cnt1 int := 0;
	sum1X number := 0;
	sum1Y number := 0;
	cnt2 int := 0;
	sum2X number := 0;
	sum2Y number := 0;
	
	cen1X number;
	cen2X number;
	
	cen1Y number;
	cen2Y number;
	
	time_stamp date;
	d_c1 TempTrain.dist_cen1%type;
	d_c2 TempTrain.dist_cen2%type;
	cl_num TempTrain.cluster_num%type;
	cnt1_zero exception;
	cnt2_zero exception;
	begin
		
		select CURRENT_TIMESTAMP into time_stamp from dual;
		dbms_output.put_line('at updateCentroid');
		
		for i in (select dist_cen1,dist_cen2,cluster_num from TempTrain) 
		loop
			
			d_c1 := i.dist_cen1;
			d_c2 := i.dist_cen2;
			cl_num := i.cluster_num;
			
			if cl_num = 1 then
				cnt1 := cnt1 + 1;
				sum1X := sum1X + d_c1;
				sum1Y := sum1Y + d_c2;
			elsif cl_num = 2 then
				cnt2 := cnt2 + 1;
				sum2X := sum2X + d_c1;
				sum2Y := sum2Y + d_c2;
			else
				dbms_output.put_line('cluster not defined');
			end if;
			
			--dbms_output.put_line(d_c1 || ' ' || d_c2 || ' ' || cl_num);

		end loop;
		
		if cnt1 = 0 then
			raise cnt1_zero;
		else 
			
			cen1X := sum1X / cnt1;
			cen1Y := sum1Y / cnt1;
			--dbms_output.put_line('at cnt1 else cen1X:' || cen1X || ' cnt1:' || cnt1 || ' cen1Y:' || cen1Y);
			--dbms_output('sum1X:'|| sum1X || 'sum1Y:'|| sum1Y);

			update CentroidsTable 
			set 
			sulfur_dixd_lvl = cen1X,
			nitro_oxid_lvl = cen1Y,
			time_stamp = time_stamp,
			u_id = u_id
			where 
			cen_id = 1;
		end if;
		
		if cnt2 = 0 then
			raise cnt2_zero;
		else 
	

			cen2X := sum2X/cnt2;
			cen2Y := sum2Y/cnt2;
			
			--dbms_output.put_line('at cnt2 else cen2X:'  || cen2X || ' cnt2:' || cnt2 || ' cen2Y:' || cen2Y);
			--dbms_output.put_line('sum2X:'|| sum2X || 'sum2Y:'|| sum2Y);
			
			update CentroidsTable 
			set 
			sulfur_dixd_lvl = cen2X,
			nitro_oxid_lvl = cen2Y,
			time_stamp = time_stamp,
			u_id  = u_id
			where 
			cen_id = 2;
		end if;
			
	exception
		when cnt1_zero then
			dbms_output.put_line('Culter 1 is not exit!');
			update CentroidsTable 
			set 
			sulfur_dixd_lvl = 0,
			nitro_oxid_lvl = 0,
			time_stamp = time_stamp,
			u_id = u_id
			where 
			cen_id = 1;
			
		when cnt2_zero then
			dbms_output.put_line('Cluter 2 is not exit!');
			update CentroidsTable 
			set 
			sulfur_dixd_lvl = 0,
			nitro_oxid_lvl = 0,
			time_stamp = time_stamp,
			u_id  = u_id
			where 
			cen_id = 2;	
	end updateCentroid; 
	
	
	procedure copyPreviousDataClusters
	is
	
	temp_c int;
	
	begin
		
		dbms_output.put_line('copyPreviousDataClusters');
		
		for i in (select cluster_num from TempTrain) 
		loop
			 --dbms_output.put_line(i.cluster_num);
			temp_c := i.cluster_num;
			clusters_list.extend;
			clusters_list(clusters_list.last) := temp_c;
		
		end loop;
	
		
		
		
	end copyPreviousDataClusters; 
	
	
	
	 procedure fitData
	is
	
	a CentroidsTable.sulfur_dixd_lvl%type;
	b CentroidsTable.nitro_oxid_lvl%type;
	c number;
	d number;
	res number;
	cnt int := 0;
	ex_init_temp_train exception;
	rows_cnt_temp_train int := 0;
	stablity_status int := 0;
	
	begin
		updateCentroid;
		copyPreviousDataClusters;
	
		select count(*) into rows_cnt_temp_train from TempTrain;
		stablity_status := clusterStabilityCheck;
		
		dbms_output.put_line('at fitdata ' || stablity_status);
		
		
		-- dbms_output.put_line('at if ');
		
		loop
		 	for j in dataset.first .. dataset.last 
			loop
				
				c := dataset(j).sulfur_dixd_lvl;
				d := dataset(j).nitro_oxid_lvl;
				
				-- dbms_output.put_line(c|| ' ' || d );
				
				cnt := 0;
				for i in (select sulfur_dixd_lvl,nitro_oxid_lvl from CentroidsTable) 
				loop
			
					a := i.sulfur_dixd_lvl;
					b := i.nitro_oxid_lvl;	
				
					res := utils.clacDistFromCen(c,d,a,b);
					
						if cnt =0 then
									
							update TempTrain 
							set 
							dist_cen1 = res
							where temp_train_id = j;
						
						elsif cnt = 1 then
						
							update TempTrain 
							set dist_cen2 = res
							where temp_train_id = j;
							
						end if;
				cnt := cnt + 1;
				
				end loop;

			end loop;
		
			for i in (select temp_train_id, dist_cen1, dist_cen2 from TempTrain) 
			loop
				
				update TempTrain 
				set cluster_num = utils.getMin(dist_cen1,dist_cen2)
				where temp_train_id = i.temp_train_id;
				
			end loop;
			
			stablity_status := clusterStabilityCheck;
			
		   exit when stablity_status = 1;
		end loop;
		
		
	exception 
		when ex_init_temp_train then
			dbms_output.put_line('Already initialized TempTrain Table!');
	
	end fitData; 
	
	
	procedure display
	is
	
	begin
	dbms_output.put_line('at display');
		FOR i IN dataset.FIRST .. dataset.LAST
		LOOP
			DBMS_OUTPUT.PUT_line(dataset(i).train_id || ' '||dataset(i).sulfur_dixd_lvl); 
		END LOOP;
	
	end display;
	
	
	procedure displayTempTrain
	is
	
	begin
	dbms_output.put_line('at displayTempTrain');
		for i in (select * from TempTrain) 
		loop
			
	dbms_output.put_line(i.temp_train_id || ' ' || i.train_id || ' ' || i.dist_cen1|| ' '|| i.dist_cen2 || ' ' || i.cluster_num);
			
		end loop;
		
	end displayTempTrain;
	
	procedure displayForLocal
	is 
	
	begin
			
		dbms_output.put_line(   'Target city:'|| select_city || chr(10) || 
								'Scope: Local' || chr(10) || 
								'Confusion Matrix:' || chr(10) ||
								'True Positive: ' || tp || chr(10) ||
								'Flase Positive: ' || fp || chr(10) ||
								'True negetive: ' || tn || chr(10) ||
								'False negetive: ' || fn || chr(10) ||
								'Precision: ' || prec || chr(10) ||
								'Recall: ' || re || chr(10) ||
								'Accuracy: '|| acc || chr(10) ||
								'F1-Score: ' || f1 || chr(10)
								);
		
	
	end displayForLocal;
	
	
	
	
	procedure displayForGlobal
	is
	
	begin
		dbms_output.put_line(	'Scope: Global' || chr(10) || 
								'Confusion Matrix:' || chr(10) ||
								'True Positive: ' || tp || chr(10) ||
								'Flase Positive: ' || fp || chr(10) ||
								'True negetive: ' || tn || chr(10) ||
								'False negetive: ' || fn || chr(10) ||
								'Precision: ' || prec || chr(10) ||
								'Recall: ' || re || chr(10) ||
								'Accuracy: '|| acc || chr(10) ||
								'F1-Score: ' || f1 || chr(10)
				
);
	end displayForGlobal;
	

end kmeans;
/

ACCEPT nam CHAR PROMPT 'Enter User Name:';


declare  

	inpt varchar(20):= 'Dhaka';
	area_type int := 1;
	userName varchar(20) := '&nam';
	
begin
	
	if kmeans.userExist(userName) = 1 then
	
		
		kmeans.getTempTrainData(inpt,area_type);
	
		--kmeans.display;
		
		kmeans.initCentroid;
		kmeans.initTempTable;
		
		--kmeans.displayTempTrain;
		
		kmeans.fitData;
		kmeans.updateCentroid;
		kmeans.predTest;
		kmeans.evaluationMetrics;
		
		if area_type = 0 then
			kmeans.displayForLocal;
		elsif area_type = 1 then
			kmeans.displayForGlobal;
		else
			dbms_output.put_line('Invalid area type');
		end if;
	
	end if;
	
	
	
	
	
end;
/
