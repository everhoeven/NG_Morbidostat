classdef PumpController
    properties
        relaybox1
        relaybox2
        
        exp_start_tic=-1;
        pumpset_1
        pumpset_2
        pumpset_3
        pumpset_4
        pumpset_5  
        pumpset_6  
        
        %log information
        media_history = []
        media_counter = 0
        drug_history = []
        drug_counter = 0
        
    end
    
    methods
        function obj=PumpController()
            obj.relaybox1 = digitalio('mcc',2) % this line will add a digital I/O device (USB-ERB08) with ID=2 
            pumpset_1 = addline(obj.relaybox1,0:3,0,'out',{'pump1';'pump2';'pump3';'pump4'})
            pumpset_2 = addline(obj.relaybox1,0:3,1,'out',{'pump5';'pump6';'pump7';'pump8'})
            
            obj.relaybox2 = digitalio('mcc',1) % this line will add a digital I/O device (USB-ERB24) with ID=1
            pumpset_3 = addline(obj.relaybox2,0:7,0,'out',{'pump9';'pump10';'pump11';'pump12';'pump13';'pump14';'pump15';'pump16'})
            pumpset_4 = addline(obj.relaybox2,0:7,1,'out',{'pump17';'pump18';'pump19';'pump20';'pump21';'pump22';'pump23';'pump24'})
            pumpset_5 = addline(obj.relaybox2,0:3,2,'out',{'pump25';'pump26';'pump27';'pump28'})
            pumpset_6 = addline(obj.relaybox2,0:3,3,'out',{'pump29';'pump30';'suction_pump';'ref_6V'})
            
            
            for i=1:8
                putvalue(obj.relaybox1.Line(i),0);
            end
            
            for i=1:24
                putvalue(obj.relaybox2.Line(i),0);
            end
        end
 
        
        % Medium pumps
        
        function TurnMediaOn(obj,val) % turn media pumps on
            for i=val
                if i<=4
                    putvalue(obj.relaybox1.Line(2*i-1),1); 
                else
                    putvalue(obj.relaybox2.Line(2*i-1-8),1); 
                end
                
                if obj.exp_start_tic >= 0
                    obj.media_counter = obj.media_counter + 1;
                    obj.media_history(obj.media_counter,:)=[i 1 toc(obj.exp_start_tic)];
                end
                
                h = fix(clock);
                disp(['Media ' num2str(i) 'is ON - ' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
            end
        end
        
        function TurnMediaOff(obj,val) % turn media pumps off
            for i=val
                if i<=4
                    putvalue(obj.relaybox1.Line(2*i-1),0); 
                else
                    putvalue(obj.relaybox2.Line(2*i-1-8),0);
                end
                
                if obj.exp_start_tic >= 0
                    obj.media_counter = obj.media_counter + 1;
                    obj.media_history(obj.media_counter,:) = [i 0 toc(obj.exp_start_tic)];
                end
                
                h = fix(clock)
                disp(['Media ' num2str(i) 'is OFF -' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
            end
        end
        
        % Drug pumps
        
        function TurnDrugOn(obj,val) % turn drug pumps on
            for i=val
                if i<=4
                    putvalue(obj.relaybox1.Line(2*i),1);
                else
                    putvalue(obj.relaybox2.Line(2*i-8),1); 
                end
                
                
                if obj.exp_start_tic >= 0
                    obj.drug_counter = obj.drug_counter + 1;
                    obj.drug_history(obj.drug_counter,:)=[i 0 toc(obj.exp_start_tic)];
                end
                
                h = fix(clock);
                disp(['Drug ' num2str(i) 'is ON - ' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
            end
        end
        
        
        function TurnDrugOff(obj,val) % turn drug pumps off
            for i=val 
                if i<=4
                    putvalue(obj.relaybox1.Line(2*i),0); 
                else
                    putvalue(obj.relaybox2.Line(2*i-8),0);
                end
                
                
                if obj.exp_start_tic >= 0
                    obj.drug_counter = obj.drug_counter + 1;
                    obj.drug_history(obj.drug_counter,:) = [i 0 toc(obj.exp_start_tic)];
                end
                
                h = fix(clock)
                disp(['Drug ' num2str(i) 'is OFF -' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
            end
        end
        
        
        % 16-channel suction pump:
       
       function TurnSuctionOn(obj,val) % turn suction pump on
           for i=23 
               putvalue(obj.relaybox2.Line(i),1);
               h = fix(clock);
               disp(['Suction ' num2str(i) 'is ON - ' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
           end
       end
       
       function TurnSuctionOff(obj,val) % turn suction pump off
           for i=23
               putvalue(obj.relaybox2.Line(i),0);
               h = fix(clock);
               disp(['Suction ' num2str(i) 'is OFF - ' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
           end
       end   
       
       % LEDs:
       
       function TurnLEDsOn(obj,val) % Turn LEDs on
           for i=24
               putvalue(obj.relaybox2.Line(i),1);
               h=fix(clock);
               disp(['LED''s ' num2str(i) 'are ON - ' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
           end
       end
       
       function TurnLEDsOff(obj,val) % Turn LEDs off
           for i=24
               putvalue(obj.relaybox2.Line(i),0);
               h=fix(clock);
               disp(['LED''s ' num2str(i) 'are OFF - ' num2str(h(4)) ':' num2str(h(5)) ':' num2str(h(6))]);
           end
       end
    end
end
