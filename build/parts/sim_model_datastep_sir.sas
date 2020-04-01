	/* DATA STEP APPROACH FOR SIR - SIMULATION APPROACH TO BOUNDS*/
		DATA DS_SIR_SIM;
			FORMAT ModelType $30. Scenarioname $30. DATE ADMIT_DATE DATE9.;		
			ModelType="DS - SIR";
			ScenarioName="&Scenario";
			ScenarioIndex=&ScenarioIndex.;
			ScenarionNameUnique=cats("&Scenario.",' (',ScenarioIndex,')');
			LABEL HOSPITAL_OCCUPANCY="Hospital Occupancy" ICU_OCCUPANCY="ICU Occupancy" VENT_OCCUPANCY="Ventilator Utilization"
				ECMO_OCCUPANCY="ECMO Utilization" DIAL_OCCUPANCY="Dialysis Utilization";
			DO DAY = 0 TO &N_DAYS;
				IF DAY = 0 THEN DO;
					S_N = &S - (&I/&DIAGNOSED_RATE) - &R;

					I_N = &I/&DIAGNOSED_RATE;
					R_N = &R;
					BETA=&BETA;
					N = SUM(S_N, I_N, R_N);
				END;
				ELSE DO;
					BETA = LAG_BETA * (1- &BETA_DECAY);
					S_N = (-BETA * LAG_S * LAG_I) + LAG_S;
					I_N = (BETA * LAG_S * LAG_I - &GAMMA * LAG_I) + LAG_I;
					R_N = &GAMMA * LAG_I + LAG_R;
					N = SUM(S_N, I_N, R_N);
					SCALE = LAG_N / N;
					IF S_N < 0 THEN S_N = 0;
					IF I_N < 0 THEN I_N = 0;
					IF R_N < 0 THEN R_N = 0;
					S_N = SCALE*S_N;
					I_N = SCALE*I_N;
					R_N = SCALE*R_N;
				END;
				E_N = &E;
				LAG_S = S_N;
				LAG_E = E_N;
				LAG_I = I_N;
				LAG_R = R_N;
				LAG_N = N;
				IF date = &ISO_Change_Date THEN BETA = &BETA_Change;
				ELSE IF date = &ISO_Change_Date_Two THEN BETA = &BETA_Change_Two;
				LAG_BETA = BETA;
/* post process here */
				OUTPUT;
			END;
			DROP LAG: BETA CUM: ;
		RUN;
		%IF &PLOTS. = YES %THEN %DO;

		%END;
		PROC APPEND base=store.MODEL_FINAL_SIM data=DS_SIR_SIM NOWARN FORCE; run;
		PROC SQL; drop table DS_SIR_SIM; QUIT;
		