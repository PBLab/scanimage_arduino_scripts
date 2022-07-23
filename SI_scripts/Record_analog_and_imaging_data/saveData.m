function saveData(fid,event)
     time = event.TimeStamps;
     data = event.Data;
     plot(time,data)
     fprintf(fid,'%f,%f,%f\n',[time,data]'); 
end