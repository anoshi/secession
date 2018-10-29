#!/bin/bash
# 
# 
#
# Sanity: Confirm we have the tools for the job and set up ENV vars for future use
which convert > /dev/null 2>&1
convert_present=$?
if [ $convert_present -ne 0 ]; then 
    echo "ImageMagick (https://imagemagick.org) 'convert' must be installed and in the system path before attempting to use this script"
    exit $convert_present;
fi

which composite > /dev/null 2>&1
composite_present=$?
if [ $composite_present -ne 0 ]; then 
    echo "ImageMagick (https://imagemagick.org) 'composite' must be installed and in the system path before attempting to use this script";
    exit $composite_present;
fi 

export MAGICK_HOME="`which convert | sed 's|/bin/convert||'`"
export DYLD_LIBRARY_PATH="$MAGICK_HOME/lib"

# Record where the script was called from (may not be pwd)
scriptdir=`dirname "$0"`
# Copy standard lookup and pattern reference images to map folder, if not already there
cp -n "$scriptdir"/map*.png . > /dev/null 2>&1

# Deal with arguments passed to the script (must be passed four alpha, terrain, and/or fx layers or script explodes)
while [[ "$#" -gt 0 ]]; do 
    case $1 in
        -a|-al|--alpha|--alpha-layers|-r|--rwr-alpha) alpha_layers="$2 $3 $4 $5"; shift 4;;
        -t|-tl|--terrain|--terrain-layers|-s|--splat) terrain_layers="$2 $3 $4 $5"; shift 4;;
        -f|-fx|-fl|-fxl|--fx|--fx-layers) fx_layers="$2 $3 $4 $5"; shift 4;;
        /?|-h|--help) echo; printf "usage: im6_process_all.sh [--alpha \e[4malpha_layers\e[0m] [--terrain \e[4mterrain_layers\e[0m] [--fx \e[4mfx_layers\e[0m]"; echo; echo; printf "example: im7_process_all.sh \e[33m-a\e[0m \e[31msand grass asphalt road\e[0m \e[33m-t\e[0m \e[32mrocky_mountain grass sand road\e[0m \e[33m-f\e[0m \e[034mnone dirtroad none none_a\e[0m"; echo; echo '* Layers must be specified in order from lowest to highest'; echo '* If no arguments are passed, the script will prompt for input'; exit;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac; 
    shift; 
done

if [[ -z $alpha_layers ]]; then 
    read -p "Are you wanting to process layers exported via the rwr_export tool in inkscape [yes/NO]? " do_rwr
    case ${do_rwr:0:1} in
        y|Y|yes|YES )
            read -p "Enter the names of the layers to be processed, in order of lowest to highest e.g. 'grass sand asphalt road': " alpha_layers;
        ;;
        * )
            alpha_layers=
        ;;
    esac
fi

# Populate array with input files (maximum of 4 for Red-Green-Blue-Alpha output image)
for layer in $alpha_layers; do
    alpha+=("_rwr_alpha_$layer.png")
done

echo
echo '1) Processing splat files: extract alpha channel, convert to 8-bit greyscale, and apply some gaussian blur'
echo

fnf=0 # file not found: false
count=0 # iterate through array
while [ $count -lt "${#alpha[@]}" ]; do
    if [[ ! -e "${alpha[$count]}" ]]; then
        echo "${alpha[$count]} is not present"; fnf=1
    else 
        out=`echo "${alpha[$count]}" | sed "s/_rwr_/terrain5_/"`
        if [[ "${alpha[$count]}" == road* || "${alpha[$count]}" == asphalt* ]]; then
            convert "${alpha[$count]}" -alpha extract -depth 8 -gaussian-blur 2x2 "$out"
        elif [[ "${alpha[$count]}" == dirt* ]]; then
            out=`echo "${alpha[$count]}" | sed "s/_rwr_/effect_/"`
            convert "${alpha[$count]}" -alpha extract -depth 8 "$out"
        else
            convert "${alpha[$count]}" -alpha extract -depth 8 -gaussian-blur 4x4 "$out"
        fi
        echo "DONE: ${alpha[$count]}"
    fi
    let count=count+1
done
if [[ $fnf -eq 1 ]]; then
    { echo "Ensure the ALPHA layer(s) listed above is present and named accordingly in your Inkscape project, run the rwr_exporter, then try this utility again." 1>&2 ; exit 1; }
fi

echo
echo '2) One-pass terrain optimisation: merge gernerated terrain splat files into one (max: 4)'
echo

if [[ -z $terrain_layers ]]; then
    if [[ ! -z $alpha_layers ]]; then
        read -p "Use the same layer names and order for this task? `echo $alpha_layers` [YES/no]? " do_rwr
        case ${do_rwr:0:1} in
            n|N|No|NO )
                read -p "Enter the four layers to be processed, in order of lowest to highest e.g. 'grass sand asphalt road': " terrain_layers;
            ;;
            * )
                terrain_layers="$alpha_layers"
            ;;
        esac
        for layer in $terrain_layers; do
            terrain+=("terrain5_alpha_$layer.png")
        done
    else
        read -p "No terrain layers specified. Allow script to proceed with best-guess defaults [YES/no]" do_proceed
        case ${do_proceed:0:1} in
            n|N|No|NO )
                { echo "Exiting. No terrain layers processed." 1>&2 ; exit 1; }
            ;;
            * )
                # Temp set Internal Field Separator to newline in order to populate local vars from find's multi-line output
                IFS='
                '
                terrain=(`find . -name 'terrain5_alpha*' | sed 's|^\./||' | sort -ru | head -4`)
                IFS=
            ;;
        esac
    fi
fi

fnf=0
count=0
while [ $count -lt "${#terrain[@]}" ]; do
    if [[ ! -e "${terrain[$count]}" ]]; then
        echo "${terrain[$count]} is not present"; fnf=1
    fi
    let count=count+1
done
if [[ $fnf -eq 1 ]]; then
    { echo "Ensure the TERRAIN file(s) listed above is present in this map folder, then try this utility again." 1>&2 ; exit 1; }
fi

echo "Building terrain5_combined_alpha.png from ${terrain[0]}, ${terrain[1]}, ${terrain[2]}, and ${terrain[3]}"
# Manually hack the convert command's arguments together
convert -colorspace RGB ${terrain[0]} -colorspace RGB ${terrain[1]} -colorspace RGB ${terrain[2]} -colorspace RGB -negate ${terrain[3]} -channel RGBA -combine terrain5_combined_alpha.png
echo
echo 'TERRAIN: done'
echo


# Combine effects layers
IFS='
'
fx_layers=(`find . -name 'effect_*' ! -name 'effect_combined_alpha.png' | sed 's|^\./||'`)
IFS=

if [[ "${#fx_layers[@]}" -eq 0 ]]; then
    echo "No effects layers to process \n"
else
    echo "Processing effects layers: ${fx_layers[@]}"
    convert -colorspace RGB effect_none.png -colorspace RGB effect_alpha_dirt*.png -colorspace RGB effect_none.png -colorspace RGB -negate effect_none_a.png -channel RGBA -combine -colorspace RGB PNG32:effect_combined_alpha.png
    echo
    echo 'EFFECTS: done'
    echo
fi


if [[ "${#alpha[@]}" -gt 0 ]]; then
    echo '3) Create heightmap from to 513x513 pixels, 8-bit greyscale'
    convert _rwr_height.png -type Grayscale -resize 513x513 -depth 8 terrain5_heightmap.png

    echo '4) Convert map_view to 512x512, output initial map.png'
    convert _rwr_map_view.png -resize 512x512 -modulate 100,0 map.png

    echo '5) Prepare map view'
    echo ' i] Convert heightmap to 8-bit greyscale'
    convert _rwr_height.png -type Grayscale -resize 4096x4096 -depth 8 -set colorspace sRGB _big_grey_height.png

    # convert _rwr_map_view_woods.png -type Grayscale -depth 8 -set colorspace sRGB _grey_woods.png'
    # convert _rwr_map_view_woods.png -modulate 100,0 _grey_woods.png
    convert _rwr_map_view_woods.png -alpha extract -depth 8 _grey_woods.png
    convert _rwr_map_view.png -modulate 100,0 _grey_objects.png

    echo ' ii] isoline'
    # use lookup table to only show specific depth levels
    convert _big_grey_height.png map_view_isoline_lookup.png -clut -resize 2048x2048 _map_isoline.png

    echo ' iii] water'
    # use lookup table to only show specific depth levels
    convert _big_grey_height.png map_view_water_lookup.png -clut -resize 2048x2048 _map_water.png

    echo ' iv] blur woods'
    # blur woods to make it spread
    convert _grey_woods.png -blur 0x20 _map_woods.png
    convert _map_woods.png map_view_woods_lookup.png -clut -negate _map_woods2.png
    # use woods area as mask for woods pattern
    convert map_view_tile_white.png map_view_woods_pattern.png _map_woods2.png -composite _map_composed_woods.png

    echo '6) Combine map views'
    count=1
    echo ' i] isolines and water'
    composite -compose Multiply _map_isoline.png _map_water.png _map_composed"$count".png

    echo ' ii] decoration'
    composite -compose DstOver _map_composed"$count".png _rwr_map_view_decoration.png _map_composed"$(($count+1))".png
    let count=count+1

    echo ' iii] woods'
    composite -compose Multiply _map_composed"$count".png _map_composed_woods.png _map_composed"$(($count+1))".png
    let count=count+1

    echo ' iv] asphalt'
    if [[ ! -e _rwr_alpha_asphalt.png ]]; then
        echo 'No asphalt. Skipping'
    else
        convert _rwr_alpha_asphalt.png -alpha extract -depth 8 _map_asphalt_mask.png
        convert _map_composed"$count".png map_view_tile_asphalt.png _map_asphalt_mask.png -composite _map_composed"$(($count+1))".png
        let count=count+1
    fi

    echo ' v] roads'
    if [[ ! -e _rwr_alpha_road.png ]]; then
        echo 'No roads. Skipping'
    else
        convert _rwr_alpha_road.png -negate -alpha extract -depth 8 _map_road_mask.png 
        convert _map_composed"$count".png map_view_tile_road.png _map_road_mask.png -negate -composite _map_composed"$(($count+1))".png
        let count=count+1
    fi

    echo ' vi] bases'
    if [[ ! -e _rwr_map_view_bases.png ]]; then
        echo 'No bases, (this sounds fatal!?). Skipping'
    else
        composite -compose DstOver _map_composed"$count".png _rwr_map_view_bases.png _map_composed"$(($count+1))".png
        let count=count+1
    fi

    echo ' vii] dirt roads'
    if [[ ! -e _rwr_alpha_dirtroad.png ]]; then
        echo 'No dirt roads. Skipping'
    else
        convert _rwr_alpha_dirtroad.png -alpha extract -depth 8 _map_dirtroad_mask.png 
        convert _map_composed"$count".png map_view_tile_dirtroad.png _map_dirtroad_mask.png -composite _map_composed"$(($count+1))".png
        let count=count+1
    fi

    echo ' vii] objects'
    composite -compose DstOver _map_composed"$count".png _grey_objects.png map.png

    echo
    echo 'map.png has been created'
    # tidy up
    rm -f _map_composed[1-"$count"].png
fi

#tidy up
rm -f map_view_*.png
echo
echo 'Finished!'
