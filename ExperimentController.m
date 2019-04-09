classdef ExperimentController < handle
    properties (Access=public)
        % objects
        datarec
        pumpcon
        datamon
        simulator
        
        % datas & timers
        data
        data_counter
        cycledata
        decisions
        cycle_counter = 0
        pause_algorithm_cycle = 0
        exp_start_tic
        tmr_readdata
        tmr_chemostatcycle
        tmr_turbidostatcycle
        tmr_morbidostatcycle
        tmr_datasaver
        data_file_path = 'data/'
        
        % parameters
        stock_conc = ones(1,15)*10; % 10MIC = stock conc
        cultures2run = 1:15
        data_point_period = 1    % (in sec) takes data every x sec
        save_data_period = 60    % (in min) saves data every x min
        experiment_time = 2      % (in days)
        
        % algortihm parameters
        dilution_factor = ones(1,15)*0.90   % dilution strength
        threshold = ones(1,15)*2.0        % turbidity threshold drug
        dilthr = ones(1,15)*1.3            % livelihood protection threshold
        mixing_time = 800                    % (sec)
        dilution_time = 30                  % (sec)
        growth_time = 1260                 % (sec)
        
        % modes
        algorithm = 'morbidostat'
        simulation_mode = 'off'
    end
    
    methods (Access = public)
        
        function obj=ExperimentController()
            daqreset;
            obj.datarec = DataReceiver;
            obj.pumpcon = PumpController;
        end
        
        
        function obj=StartExperiment(obj)
            max_data_point_to_be_collected = floor((86400/obj.data_point_period)*obj.experiment_time);    
            max_number_of_cycles_to_be_run = floor((86400/(obj.growth_time+obj.dilution_time))*obj.experiment_time);
            
            obj.data = zeros(max_data_point_to_be_collected,16);
            obj.data_counter = 0;
            for i=1:max(obj.cultures2run)
                obj.cycledata(i).Drug = zeros(1,max_number_of_cycles_to_be_run);
                obj.cycledata(i).finalTurbidity = zeros(1,max_number_of_cycles_to_be_run);
                obj.cycledata(i).Proportion = zeros(1,max_number_of_cycles_to_be_run); % P
                obj.cycledata(i).Derivative = zeros(1,max_number_of_cycles_to_be_run); % D
                obj.cycledata(i).Integral = zeros(1,max_number_of_cycles_to_be_run);   % I
                obj.cycledata(i).PID = zeros(1,max_number_of_cycles_to_be_run);        % PID
            end
            
            obj.datamon = DataMonitor;
            obj.exp_start_tic = tic;
            obj.datarec.exp_start_tic = uint64(obj.exp_start_tic);
            obj.pumpcon.exp_start_tic = uint64(obj.exp_start_tic);
            obj.datamon.exp_start_tic = uint64(obj.exp_start_tic);
            
            obj.tmr_readdata = timer('ExecutionMode','fixedRate',...
                'Period',obj.data_point_period,'TasksToExecute',max_data_point_to_be_collected,...
                'TimerFcn',@obj.get_data_fcn,'StopFcn',@obj.destroy_yourself);
            obj.tmr_datasaver = timer('ExecutionMode','fixedRate',...
                'Period',obj.save_data_period*60,'TasksToExecute',floor((86400/obj.save_data_period)*obj.experiment_time),...
                'TimerFcn',@obj.save_data_fcn,'StopFcn',@obj.destroy_yourself);
            obj.tmr_chemostatcycle = timer('ExecutionMode','fixedRate',...
                'Period',(obj.growth_time+obj.dilution_time),'TasksToExecute',max_number_of_cycles_to_be_run,'TimerFcn',@obj.RunAChemostatCycle,...
                'startDelay',0,'StopFcn',@obj.destroy_yourself);
            obj.tmr_turbidostatcycle = timer('ExecutionMode','fixedRate',...
                'Period',(obj.growth_time+obj.dilution_time),'TasksToExecute',max_number_of_cycles_to_be_run,'TimerFcn',@obj.RunATurbidostatCycle,...
                'startDelay',0,'StopFcn',@obj.destroy_yourself); 
            obj.tmr_morbidostatcycle = timer('ExecutionMode','fixedRate',...
                'Period',(obj.growth_time+obj.dilution_time),'TasksToExecute',max_number_of_cycles_to_be_run,'TimerFcn',@obj.RunAMorbidostatCycle,...
                'startDelay',0,'StopFcn',@obj.destroy_yourself);
            start([obj.tmr_readdata obj.tmr_datasaver]);
            if strcmp(obj.algorithm,'chemostat') 
                start(obj.tmr_chemostatcycle);
            elseif strcmp(obj.algorithm,'turbidostat')
                start(obj.tmr_turbidostatcycle);
            elseif strcmp(obj.algorithm,'morbidostat')
                start(obj.tmr_morbidostatcycle);
            end
        end
        
        
        function StopExperiment(obj)
            stop([obj.tmr_readdata obj.tmr_chemostatcycle obj.tmr_datasaver]);
            delete([obj.tmr_readdata obj.tmr_chemostatcycle obj.tmr_datasaver]);
            obj.pumpcon.TurnMediaOff(obj.cultures2run);
            obj.pumpcon.TurnSuctionOff(obj.cultures2run);
        end
        
        
        % CHEMOSTAT CYCLE:
        
        function RunAChemostatCycle(obj,timerObj,timerE) 
            if obj.pause_algorithm_cycle==1
                return;
            end
            
            lastdata = obj.data(obj.data_counter,:);
            for i=obj.cultures2run
                if lastdata(1,i) > obj.dilthr(1,i)
                    obj.pumpcon.TurnMediaOn(i);
                    tmr_turnmedia_off = timer('ExecutionMode','singleShot','startDelay',obj.dilution_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnMediaOff(i),...
                        'StopFcn',@obj.destroy_yourself);
                    tmr_turnsuction_on = timer('ExecutionMode','singleShot','startDelay',23*obj.dilution_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnSuctionOn(i),...
                        'StopFcn',@obj.destroy_yourself);
                    tmr_turnsuction_off = timer('ExecutionMode','singleShot','startDelay',24*obj.dilution_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnSuctionOff(i),...
                        'StopFcn',@obj.destroy_yourself);
                    start([tmr_turnmedia_off tmr_turnsuction_on tmr_turnsuction_off]);
                end
            end
        end     
        
        % TURBIDOSTAT CYCLE:

        function RunATurbidostatCycle(obj,timerObj,timerE) 
             if obj.pause_algorithm_cycle==1
                return;
            end
            lastdata = obj.data(obj.data_counter,:);
            for i=obj.cultures2run
                if lastdata(1,i) > obj.threshold(1,i)
                    obj.pumpcon.TurnMediaOn(i);
                    tmr_turnmedia_off = timer('ExecutionMode','singleShot','startDelay',obj.dilution_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnMediaOff(i),...
                        'StopFcn',@obj.destroy_yourself);
                    tmr_turnsuction_on = timer('ExecutionMode','singleShot','startDelay',obj.dilution_time+obj.mixing_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnSuctionOn(i),...
                        'StopFcn',@obj.destroy_yourself);
                    tmr_turnsuction_off = timer('ExecutionMode','singleShot','startDelay',3*obj.dilution_time+obj.mixing_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnSuctionOff(i),...
                        'StopFcn',@obj.destroy_yourself);
                    start([tmr_turnmedia_off tmr_turnsuction_on tmr_turnsuction_off]);
                end
            end
        end        
            
        % MORBIDOSTAT CYCLE:
        
        function RunAMorbidostatCycle(obj,timerObj,timerE)
             if obj.pause_algorithm_cycle==1
                return;
            end
            obj.cycle_counter = obj.cycle_counter + 1;
            obj.CalculatePID()
            obj.decisions(obj.cycle_counter).logic_choice = obj.LogicDecision()
            
            for i=obj.cultures2run 
                    tmr_turnmedia_off = timer('ExecutionMode','singleShot','startDelay',obj.dilution_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnMediaOff(i),'StopFcn',@obj.destroy_yourself);
                    tmr_turndrug_off = timer('ExecutionMode','singleShot','startDelay',obj.dilution_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnDrugOff(i),'StopFcn',@obj.destroy_yourself);              
                    tmr_turnsuction_on = timer('ExecutionMode','singleShot','startDelay',obj.dilution_time+obj.mixing_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnSuctionOn(i),'StopFcn',@obj.destroy_yourself);
                    tmr_turnsuction_off = timer('ExecutionMode','singleShot','startDelay',3*obj.dilution_time+obj.mixing_time,...
                        'TimerFcn',@(event,data)obj.pumpcon.TurnSuctionOff(i), 'StopFcn',@obj.destroy_yourself);
                    
                    if obj.decisions(obj.cycle_counter).logic_choice(i).Media
                        obj.pumpcon.TurnMediaOn(i); start(tmr_turnmedia_off);
                    end
                    if obj.decisions(obj.cycle_counter).logic_choice(i).Drug
                        obj.pumpcon.TurnDrugOn(i); start(tmr_turndrug_off);
                    end  
                    if obj.decisions(obj.cycle_counter).logic_choice(i).Media || ...
                        obj.decisions(obj.cycle_counter).logic_choice(i).Drug
                       start([tmr_turnsuction_on tmr_turnsuction_off]);
                    end 
                    if obj.cycle_counter == 1
                        obj.cycledata(i).Drug(obj.cycle_counter) = obj.decisions(obj.cycle_counter).logic_choice(i).Drug*obj.stock_conc(1,i)*(1 - obj.dilution_factor(1,i));
                    else
                        obj.cycledata(i).Drug(obj.cycle_counter) = obj.cycledata(i).Drug(obj.cycle_counter-1)*obj.dilution_factor(1,i) + obj.decisions(obj.cycle_counter).logic_choice(i).Drug*obj.stock_conc(1,i)*(1 - obj.dilution_factor(1,i));
                    end
            end
        end
        
        function LogicChoise=LogicDecision(obj) 
            lastdata = obj.data(obj.data_counter,:);
            
            for i=obj.cultures2run
                if lastdata(1,i) > obj.dilthr(1,i)
                    if obj.cycledata(i).PID(obj.cycle_counter) > 0
                        LogicChoise(i).Drug = 1
                        LogicChoise(i).Media = 0
                    else
                        LogicChoise(i).Drug = 0
                        LogicChoise(i).Media = 1
                    end
                else
                    LogicChoise(i).Drug = 0;
                    LogicChoise(i).Media = 0;
                end
            end
        end
        
        
        function CalculatePID(obj)
            lastdata = obj.data(obj.data_counter,:);
            for i=obj.cultures2run
                obj.cycledata(i).finalTurbidity(obj.cycle_counter) = lastdata(1,i);
                obj.cycledata(i).Proportion(obj.cycle_counter)= obj.cycledata(i).finalTurbidity(obj.cycle_counter)-obj.threshold(1,i); 
                obj.cycledata(i).Derivative(obj.cycle_counter)= obj.cycledata(i).finalTurbidity(obj.cycle_counter)-obj.cycledata(i).finalTurbidity(max(1,obj.cycle_counter-1));
                obj.cycledata(i).Integral(obj.cycle_counter)=sum(obj.cycledata(i).Proportion(max(1,obj.cycle_counter-5):obj.cycle_counter));
                obj.cycledata(i).PID(obj.cycle_counter)=(obj.cycledata(i).Proportion(obj.cycle_counter)>0)*1e5-(obj.cycledata(i).Proportion(obj.cycle_counter)<0)*1e5 ......
                    +0.001*obj.cycledata(i).Integral(obj.cycle_counter)...
                    +obj.cycledata(i).Derivative(obj.cycle_counter);
            end
        end
        function get_data_fcn(obj, timerObj, timerEvent)
            
            lastdata = obj.datarec.readTurbidity;
            
            obj.data_counter = obj.data_counter + 1;
            timeSinceNow = toc(obj.exp_start_tic);
            obj.data(obj.data_counter,:) = [lastdata timeSinceNow];
            for i=obj.cultures2run
                obj.datamon.AddDataPoint(i,timeSinceNow,lastdata(1,i));
            end
        end
        
        function save_data_fcn(obj, timerObj, timerEvent)
            hgsave(obj.datamon.fig, [obj.data_file_path 'data_' datestr(now, 'dd-mm-yyyy_HH-MM-SS_AM') '.fig']);
            data2save = obj.data(1:obj.data_counter,:);
            try
                save([obj.data_file_path 'data_' datestr(now, 'dd-mm-yyyy_HH-MM-SS_AM') '.mat'], 'data2save');
            catch err
                err;
                disp('Data save skipped due to an error.');
            end
            try
                save([obj.data_file_path 'whole_experiment_' datestr(now, 'dd-mm-yyyy_HH-MM-SS_AM') '.mat'], 'obj');
            catch err
                err;
                disp('Data save skipped due to an error.');
            end
        end
        
        function destroy_yourself(obj,timerObj,timerEvent)
            delete(timerObj);
        end
        
        function delete(obj)
            delete(obj.tmr_readdata);
        end
    end
end

