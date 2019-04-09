classdef DataMonitor < handle
    
    properties
      fig    % figure handle
      axs    % axes handle
      lins   % plot handles
      
      cmap=[.662 0.2 0.166; 0.54 0.133 0.36; 0.38 0.12 0.45; 0.29 0.14 0.46; 0.16 0.18 0.47; 0.14 0.25 0.45; 0.12 0.31 0.43; 0.10 0.41 0.40; 0.11 0.48 0.28; 0.27 0.58 0.14; 0.43 0.62 0.15; 0.54 0.65 0.16; 0.67 0.60 0.16; 0.67 0.44 0.16; 0.67 0.16 0.17] % Color for the primary graph. 15 x 3, mogelijks error omdat wij maar 2 pompen hebben per flesje?
      exp_start_tic
    
    end
    
    
    methods
        function obj=DataMonitor()
            obj.fig = figure('Name',['Started at ' datestr(now,'mmmm dd,yyyy HH:MM AM')]);
            for i=1:15
                obj.axs{i} = subplot(5,3,i); 
                obj.lins{i} = plot(obj.axs{i},0,0);
                set(obj.lins{i},'Color',obj.cmap(i,:));
                xlabel('hours');
                ylabel(['Culture - ' num2str(i) 'Turbidity']);
                grid on
            end
        end
        
        
        function AddDataPoint(obj,culture,x,y)
            set(obj.lins{culture},'XData',[get(obj.lins{culture},'XData') x/3600]);
            set(obj.lins{culture},'Ydata',[get(obj.lins{culture},'YData') y]);
        end
    end
end
