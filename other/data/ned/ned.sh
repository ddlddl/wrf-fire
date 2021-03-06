#!/bin/bash

output_dir="highres_elev$2"

function get_param
{
  local fname
  local pname
  fname=$1
  pname=$2
  pval=$(grep -a $pname $fname | sed "s/^${pname}  *//" | sed 's/ *//g' | tr -d '\r' )
}

function split_string
{
  local str
  str=$(echo $1 | sed 's/^ *//' | sed 's/ *$//' | sed 's/  */ /g')
  pdeg=$(echo $str | cut -s -d " " -f 1)
  pmin=$(echo $str | cut -s -d " " -f 2)
  psec=$(echo $str | cut -s -d " " -f 3)
}

function get_origin_params
{
  local fname
  local pval
  local sstr
  fname=$1
  sstr='\/\* 1st standard parallel'
  par1str=$(grep -a "$sstr" $fname | sed "s/ *${sstr}.*$//" | tr -d '\r')
  split_string "$par1str"
  par1deg=$pdeg
  par1min=$pmin
  par1sec=$psec
  sstr='\/\* 2nd standard parallel'
  par2str=$(grep -a "$sstr" $fname | sed "s/ *${sstr}.*$//" | tr -d '\r')
  split_string "$par2str"
  par2deg=$pdeg
  par2min=$pmin
  par2sec=$psec
  sstr='\/\* central meridian'
  merstr=$(grep -a "$sstr" $fname | sed "s/ *${sstr}.*$//" | tr -d '\r')
  split_string "$merstr"
  merdeg=$pdeg
  mermin=$pmin
  mersec=$psec
  sstr='\/\* latitude of projection'
  latstr=$(grep -a "$sstr" $fname | sed "s/ *${sstr}.*$//" | tr -d '\r')
  split_string "$latstr"
  latdeg=$pdeg
  latmin=$pmin
  latsec=$psec
  sstr='\/\* false easting'
  falseeast=$(grep -a "$sstr" $fname | sed "s/ *${sstr}.*$//" | tr -d '\r')
  sstr='\/\* false northing'
  falsenorth=$(grep -a "$sstr" $fname | sed "s/ *${sstr}.*$//" | tr -d '\r')
}

function read_headers
{
  local dir fname
  dir=$1
  fname="${dir}/${dir}.prj"
  get_param $fname Projection
  proj="$pval"
  get_param $fname Datum
  datum="$pval"
  get_param $fname Spheroid
  speroid="$pval"
  get_param $fname Units
  units="$pval"
  get_param $fname Zunits
  zunits="$pval"
 
  #get_origin_params $fname

  fname="${dir}/${dir}.hdr"
  get_param $fname ncols
  ncols="$pval"
  get_param $fname nrows
  nrows="$pval"
  get_param $fname xllcorner
  xll="$pval"
  get_param $fname yllcorner
  yll="$pval"
  get_param $fname cellsize
  cellsize="$pval"
  get_param $fname NODATA_value
  nodata="$pval"
  get_param $fname byteorder
  byteorder="$pval"

}

read_headers $1
rm -fr "$output_dir" &> /dev/null
mkdir -p "$output_dir" &> /dev/null
idx="$output_dir/index"

if [ "$proj" == "GEOGRAPHIC" ] && [ "$datum" == "NAD83" ] ; then
  nproj=1
  echo "projection=regular_ll" >> $idx
else
  echo "Projection $proj $datum not supported"
  exit 1
fi

echo 'type=continuous' >> $idx
echo 'units="meters"' >> $idx
echo 'description="National Elevation Dataset (NED)"' >> $idx

if [ $nproj -eq 1 ] && [ $units == DD ] ; then
  echo "dx=$cellsize" >> $idx
  echo "dy=$cellsize" >> $idx
else
  echo "Unit conversion for $units to degrees not supported"
  exit 1
fi

echo 'known_x=1' >> $idx
echo 'known_y=1' >> $idx

echo "known_lat=${yll}" >> $idx
echo "known_lon=${xll}" >> $idx

echo 'wordsize=2' >> $idx
echo 'tile_bdr=3' >> $idx
echo 'missing_value=0' >> $idx
echo 'scale_factor=1' >> $idx
echo 'row_order=bottom_top' >> $idx

if [ $byteorder == LSBFIRST ] ; then
  echo 'endian=little' >> $idx
else
  echo "bad byte order"
  exit 1
#  echo 'endian=big' >> $idx
fi

echo "tile_x=1000" >> $idx
echo "tile_y=1000" >> $idx
echo "tile_z=1" >> $idx

./convert_ned.x ${1}/${1}.flt $nrows $ncols
mv *-*.*-*  "$output_dir"

