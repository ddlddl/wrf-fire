function [fxlong,fxlat,fire_area]=read_file_perimeter(wrfout,time)
% Volodymyr Kondratenko           April 3 2012

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Input:    data : String - data, that contains the name of the Text file.
%                  First 2 columns - coordinates of all the
%                  points on the boundary (lon,lat). 
%                  1rt row - time_now (second number is not needed, is set to 0);
%                  2nd row - size of the mesh;
%                  3rd row - coordinates of ignition point;
%                  All next rows - coordinates of all the
%                  points on the boundary (lon,lat). %       
%         wrfout : String with the name of the wrfout file,  
%                  It is needed for reading the latitude and longtitude
%                  coordinates of the mesh and also UNIT_FXLONG and
%                  UNIT_FXLAT variables
%        time    : coordinate in the wrfout array, that needs to be computed
%                  example FXLAT(:,:,time)  
% Output: 
%        unit_long = UNIT_FXLONG;
%        unit_lat = UNIT_FXLAT;
%        long = FXLONG, longtitude coordinates of the mesh
%        lat = FXLAT, latitude coordinates of the mesh 
%        time_now = time of ignition on the boundary
%        mesh_size = size of the mesh
%        ign_pnt - point of ignition
%        bound - set of ordered points of the boundary 1st=last 
%        bound(i,1)-horisontal; bound(i,1)-vertical coordinate





p=nc2struct(wrfout,{'UNIT_FXLONG','UNIT_FXLAT','FXLONG','FXLAT','FIRE_AREA'},{},time)

fxlong=p.fxlong*p.unit_fxlong;
fxlat=p.fxlat*p.unit_fxlat;
fire_area=p.fire_area;

end


function bound=read_perim_from_file(data,unit_long,unit_lat);
fid = fopen(data);
bound = fscanf(fid,'%17g %*1s %17g %*3s',[2 inf]);

bound = bound';
fclose(fid);

bound(:,1)=bound(:,1)*unit_long;
bound(:,2)=bound(:,2)*unit_lat;
end

