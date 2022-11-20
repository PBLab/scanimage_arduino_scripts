function saveData(fid,event)

     time = event.TimeStamps;
     data = event.Data;
     %plot(time,data)
     str = [repmat('%f,',1,size(data,2)) '%f\n'];
     fprintf(fid,str,[time,data]'); 
end