
classdef DataReceiver
    properties
        ai
        listbg = [0.1666,0.2551,0.1556,0.219,0.2882,0.1439,0.2647,0.1935,0.2619,0.2432,0.2705,0.2089,0.3378,0.4337,0.2505]; % Background calibratie(TURBIDITEIT)
        listratio = [7.3006,6.6686,5.4026,7.2306,7.2938,10.004,9.5394,6.974,6.7885,7.2864,8.12,6.4122,8.4798,13.944,8.1654]; % Ratio calibratie (TURBIDITEIT)
        samplerate = 1000
        timeout = 1
        channels
        rawdata
        turbidity
        
        exp_start_tic
    end
    
    methods
        function obj=DataReceiver() 
            obj.ai = analoginput('mcc',0);
            obj.channels = addchannel(obj.ai,0:14);
            set(obj.ai,'SampleRate',1000);
            set(obj.ai,'SamplesPerTrigger',500);
            set(obj.ai,'Timeout',1);
        end
        
        
        function obj=set.timeout(obj,value)
            obj.timeout = value;
            set(obj.ai,'Timeout',obj.timeout);
            set(obj.ai,'SamplesPerTrigger',(obj.samplerate/2)*obj.timeout);
        end
        
        
        function obj=set.samplerate(obj,value)
            obj.samplerate=value;
            set(obj.ai,'SampleRate',obj.samplerate);
            set(obj.ai,'SamplesPerTrigger',(obj.samplerate/2)*obj.timeout);
        end
        
        
        function turbidity=readTurbidity(obj) 
            try
                start(obj.ai);
                rawdata=median(getdata(obj.ai));
                stop(obj.ai);
                turbidity = (obj.listratio.*rawdata)-obj.listbg
            catch err 
                err;
                disp('DAQ device is not responded!');
                turbidity = zeros(1,15) 
            end
        end
        
        
        function rawdata=ReadVoltage(obj)
            try
                start(obj.ai);
                rawdata = median(getdata(obj.ai));
                stop(obj.ai);
            catch err
                err;
                disp('DAQ device is not responded!');
                rawdata = zeros(1,16);
            end
        end
    end
end
