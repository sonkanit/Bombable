#adjust friction etc per terrain
var terrain_survol = func (id) {

  var loopid=getprop("/environment/terrain-info/terrain_servol_loopid");
  if (loopid==nil) terrain_survol_loopid=0;
  id==loopid or return;
  settimer (func {terrain_survol(id)}, 0.04734);  
  
  var lat = getprop("/position/latitude-deg");
  var lon = getprop("/position/longitude-deg");
  var info = geodinfo(lat, lon);
  var agl_ft = getprop("/fdm/jsbsim/position/h-agl-ft");
  
  #We are using groundspeed_kt to set the rate per second that dust & wake 
  #particles are displayed.  But sometimes under JSBSim groundspeed_kt goes crazy high.
  #Here we make a limited version of groundspeed that will suit our purposes
  #and always remain within sane bounds
  var groundspeed_kt = getprop("/velocities/groundspeed-kt");
  var groundspeed_kt_trimmed=groundspeed_kt;
  if (groundspeed_kt_trimmed==nil) groundspeed_kt_trimmed=0;
  if (groundspeed_kt_trimmed<0) groundspeed_kt_trimmed=0;
  if (groundspeed_kt_trimmed>75) groundspeed_kt_trimmed=75;
  var wake_dust_rate=groundspeed_kt_trimmed;
  setprop("/environment/terrain-info/wake-dust-rate", wake_dust_rate);
  if ((info != nil) and info[1].solid==0 and groundspeed_kt_trimmed<10)  {
             wake_dust_rate=math.sqrt(math.sqrt(math.sqrt(math.sqrt(groundspeed_kt_trimmed/10))))*20; }
  setprop("/environment/terrain-info/wake-dust-rate", wake_dust_rate); 
             

  if ( (info != nil) and (info[1] != nil) ) { #rand()<.1 slows down the rate of bumpiness, which seems to work better than doing it too frequently   
          if (info[1].solid ==nil) info[1].solid = 1;
          setprop("/environment/terrain-info/terrain",info[1].solid);   # 1 if solid land, 0 if water
          #the crash-detect subroutine can only read within the /fdim/jsbsim hierarchy so we must put this there as well
          setprop("/fdm/jsbsim/terrain-info/terrain",info[1].solid);   # 1 if solid land, 0 if water

          # If on water we're going to #1 double the wake rate because water puts up a bunch of spracy etc. And #2 bolster the wake rate at slow speeds to make more of a splash as the a/c settles into the water etc.
          

          var wheel_speed0_fps=getprop ("/fdm/jsbsim/gear/unit[0]/wheel-speed-fps");
          var wheel_speed2_fps=getprop ("/fdm/jsbsim/gear/unit[2]/wheel-speed-fps");
          var wheel_speed_fps=wheel_speed0_fps;
          if (wheel_speed2_fps> wheel_speed_fps) wheel_speed_fps=wheel_speed2_fps;
          
          if (info[1].bumpiness ==nil) info[1].bumpiness = 0;
          if (info[1].solid == 0 ) info[1].bumpiness = 1.2; # we're making water automatically quite 'bumpy'
          var bumpinesscoeff=info[1].bumpiness*15;
          var speedbumpinesscoeff=20;          
          
          setprop("/environment/terrain-info/terrain-bumpiness",info[1].bumpiness);

          if (rand()<.2) {   # we do the gear height adjustments only part of the time to reduce the frequency of the bumps and make them more realistic

              # we're experimenting with special paramenters for water to make it more realistic.   
              
              if (info[1].solid == 0 ) { #ie, over water
                # if the a/c is far enough under water that the prop strikes water, then the engine quits
                if (agl_ft < 3.0) setprop ("/controls/engines/engine/magnetos",0);
                
                # on water, we 'raise the gear' so that the a/c will appear
                # to be partially submerged when it lands
                # this sets the gear contact points to be basically the bottom of the fuselage
    
                #R gear & it's protective structure element
                var bump = (bumpinesscoeff * rand()-bumpinesscoeff)*(rand() < wheel_speed_fps/speedbumpinesscoeff);
                setprop ("/fdm/jsbsim/gear/unit[0]/z-position", -20 + bump );
                setprop ("/fdm/jsbsim/contact/unit[21]/z-position", -20 + bump );
                
                #L gear & it's protective structure element
                var bump = (bumpinesscoeff * rand()-bumpinesscoeff)*(rand() < wheel_speed_fps/speedbumpinesscoeff);
                setprop ("/fdm/jsbsim/gear/unit[1]/z-position", -20 + bump );
                setprop ("/fdm/jsbsim/contact/unit[22]/z-position", -20 + bump );
                
                #water gear - same bump for both, a bit different than land gear
                var bump = (bumpinesscoeff * rand()-bumpinesscoeff)*(rand() < wheel_speed_fps/speedbumpinesscoeff);
                setprop ("/fdm/jsbsim/gear/unit[2]/z-position",-60 + bump * 3 );
                setprop ("/fdm/jsbsim/gear/unit[3]/z-position",-60 + bump * 3 );
                
                #tail
                setprop ("/fdm/jsbsim/gear/unit[4]/z-position",-12 + (bumpinesscoeff 
    * rand()-bumpinesscoeff)*(rand() < wheel_speed_fps/speedbumpinesscoeff));
                
                #prop bottom, prop top, upper wing l, middle, r
                setprop ("/fdm/jsbsim/contact/unit[9]/z-position",25);
                setprop ("/fdm/jsbsim/contact/unit[10]/z-position",25);
                setprop ("/fdm/jsbsim/contact/unit[13]/z-position",-25); # this is the bottom of the prop; in water it's not really a hard contact point                 
                setprop ("/fdm/jsbsim/contact/unit[12]/z-position",25);
                setprop ("/fdm/jsbsim/contact/unit[14]/z-position",25);
                setprop ("/fdm/jsbsim/contact/unit[15]/z-position",25);
                setprop ("/fdm/jsbsim/contact/unit[16]/z-position",15);
                setprop ("/fdm/jsbsim/contact/unit[17]/z-position",5);
                setprop ("/fdm/jsbsim/contact/unit[18]/z-position",0);
                setprop ("/fdm/jsbsim/contact/unit[19]/z-position",-5);   
                        
                
              } else { # ie, over land
                # on land we set the gear back to normal levels so that 
                # the a/c rolls/drags across land
                # this sets the gear contact points to be the bottom of the
                # tires/rear dragger
    
                #R gear & it's protective structure element
                var bump = (bumpinesscoeff * rand()-bumpinesscoeff)*(rand() < wheel_speed_fps/speedbumpinesscoeff);
                setprop ("/fdm/jsbsim/gear/unit[0]/z-position",-65 + bump );
                setprop ("/fdm/jsbsim/contact/unit[21]/z-position",-55 + bump );
                
                #L gear & it's protective structure element
                var bump = (bumpinesscoeff * rand()-bumpinesscoeff)*(rand() < wheel_speed_fps/speedbumpinesscoeff);
                setprop ("/fdm/jsbsim/gear/unit[1]/z-position",-65 + bump );
                setprop ("/fdm/jsbsim/contact/unit[22]/z-position",-55 + bump );
    
    
                setprop ("/fdm/jsbsim/gear/unit[2]/z-position",-55);  #we set the water gear to -55 here, rather than fully retracting to -20, so that on hard bumps on the solid ground it will emit some dust
                setprop ("/fdm/jsbsim/gear/unit[3]/z-position",-55);
                
                #tail
                setprop ("/fdm/jsbsim/gear/unit[4]/z-position",-18 + (bumpinesscoeff 
    * rand()-bumpinesscoeff)*(rand() < wheel_speed_fps/speedbumpinesscoeff));               
                #prop bottom, prop top, upper wing l, middle, r
                setprop ("/fdm/jsbsim/contact/unit[9]/z-position",62);
                setprop ("/fdm/jsbsim/contact/unit[10]/z-position",62);
                setprop ("/fdm/jsbsim/contact/unit[13]/z-position",-59); 
                setprop ("/fdm/jsbsim/contact/unit[12]/z-position",59);
                setprop ("/fdm/jsbsim/contact/unit[14]/z-position",56);
                setprop ("/fdm/jsbsim/contact/unit[15]/z-position",56);
                setprop ("/fdm/jsbsim/contact/unit[16]/z-position",56);
                setprop ("/fdm/jsbsim/contact/unit[16]/z-position",48);
                setprop ("/fdm/jsbsim/contact/unit[17]/z-position",38);
                setprop ("/fdm/jsbsim/contact/unit[18]/z-position",32);
                setprop ("/fdm/jsbsim/contact/unit[19]/z-position",28);       
              
              }
          }     
          if (info[1].load_resistance ==nil) info[1].load_resistance = 1e+30;
          if (info[1].solid == 0 ) info[1].load_resistance = 1; # we're experimenting with special paramenters for water to make it more realistic
          setprop("/environment/terrain-info/terrain-load-resistance",info[1].load_resistance);
          
          if (info[1].friction_factor ==nil) info[1].friction_factor = 1.05; 
          if (info[1].solid == 0 ) info[1].friction_factor = .9; # we're experimenting with special paramenters for water to make it more realistic
          setprop("/environment/terrain-info/terrain-friction-factor",info[1].friction_factor);
                    
          
          
          if (info[1].rolling_friction ==nil) info[1].rolling_friction = 0.02;
          
          # we're experimenting with special paramenters for water to make it more realistic.   
          if (info[1].solid == 0 ) {
            var rfriction=.4;
            if (agl_ft < 5.5) rfriction=.4;
            if (agl_ft < 4.5) rfriction=.6;
            if (agl_ft < 3.75) rfriction=.6;
            if (agl_ft < 3.0) rfriction=.6;
            if (agl_ft < 2.5) rfriction=.6;
            if (agl_ft < 2) rfriction=.9;
            info[1].rolling_friction = rfriction;
            
          }

          setprop("/environment/terrain-info/terrain-rolling-friction",info[1].rolling_friction);
          
          if (info[1].names ==nil) info[1].names="";
          setprop("/environment/terrain-info/names",info[1].names[0]); 
                   
      } else {
        setprop("/environment/terrain-info/terrain",1);  # 1 if solid land, 0 if water
        #the crash-detect subroutine can only read within the /fdim/jsbsim hierarchy so we must put this there as well
        setprop("/fdm/jsbsim/terrain-info/terrain",1);   # 1 if solid land, 0 if water

        setprop("/environment/terrain-info/terrain-load-resistance",1e+30);
        setprop("/environment/terrain-info/terrain-friction-factor",1.05);
        setprop("/environment/terrain-info/terrain-bumpiness",0);
        setprop("/environment/terrain-info/terrain-rolling-friction",0.02);
      }
      
  #updates friction data for each contact point/gear element based on current location
  friction_loop();
  
  #creates a trimmed version of the current compression-ft amount
  #for each gear setting/element point for use in the wake/dust particle system    
  contact_point_compression_limiter_loop(0,5,wake_dust_rate);
}




var friction_init =func {
  for (var n=0;n<getprop("/fdm/jsbsim/gear/num-units"); n+=1) {
    
    var x = getprop("/fdm/jsbsim/gear/unit["~n~"]/side_friction_coeff");
    if (x==nil) x=0;
    setprop ("/environment/terrain-info/gear/unit["~n~"]/side_friction_coeff_aircraft",x );
    
    var x = getprop("/fdm/jsbsim/gear/unit["~n~"]/static_friction_coeff");
    if (x==nil) x=0; 
    setprop ("/environment/terrain-info/gear/unit["~n~"]/static_friction_coeff_aircraft", x );

    var x = getprop("/fdm/jsbsim/gear/unit["~n~"]/dynamic_friction_coeff");
    if (x==nil) x=0; 
    setprop ("/environment/terrain-info/gear/unit["~n~"]/dynamic_friction_coeff_aircraft", x );
    
    var x = getprop("/fdm/jsbsim/gear/unit["~n~"]/rolling_friction_coeff");
    if (x==nil) x=0; 
    setprop ("/environment/terrain-info/gear/unit["~n~"]/rolling_friction_coeff_aircraft", x );
    
    print ("Camel/JSBSim: Aircraft friction parameters initialized");
  } 
}  
    
var friction_loop = func {

  for (var n=0;n<getprop("/fdm/jsbsim/gear/num-units"); n+=1) {
    var tff=getprop("/environment/terrain-info/terrain-friction-factor" );
    if (tff==nil) tff=1;
    
    setprop ("/fdm/jsbsim/gear/unit["~n~"]/side_friction_coeff",
     getprop("/environment/terrain-info/gear/unit["~n~"]/side_friction_coeff_aircraft") *
     tff ) ;
    
    var bff= getprop("/environment/terrain-info/gear/unit["~n~"]/static_friction_coeff_aircraft");
    #print (bff==nil, " ", n);
    setprop ("/fdm/jsbsim/gear/unit["~n~"]/static_friction_coeff",
      bff * tff ) ;
    
    setprop ("/fdm/jsbsim/gear/unit["~n~"]/dynamic_friction_coeff",
     getprop("/environment/terrain-info/gear/unit["~n~"]/dynamic_friction_coeff_aircraft") *
     tff);    
     
    setprop ("/fdm/jsbsim/gear/unit["~n~"]/rolling_friction_coeff",
     getprop("/environment/terrain-info/gear/unit["~n~"]/rolling_friction_coeff_aircraft") +
     getprop("/environment/terrain-info/terrain-rolling-friction" ) ) ;
     
  } 
  
  #print ("Camel/JSBSim: Friction parameters updated");
}  

###################################################################
#COMPRESSION_FT TRIM AND WAKE/DUST FACTOR CALCULATION
#this gets the amount of compression for each contact point or gear element
#but (important!) trims it down to between min & max
#this is used in the wake/dust particle system. 
#
#Then it multiplies it by a trimmed version of the current groundspeed (
#calculated above).
#That way our wake or dust is proportional to both the speed and the amount of 
#pressure on that contact point. We might be able to add other interesting
#factors later, such as the type of terrain (water, ground, paved, unpaved, etc)
#
#See camel-effect.xml and the files in Models\Effects\wake for more info
#   
var contact_point_compression_limiter_loop = func ( min=0, max=5, low_limit=.005, zero_round=.00001, multiplier=10) {                                              

     for (var n=0;n<getprop("/fdm/jsbsim/gear/num-units"); n+=1) {
        unitName= "unit[" ~ n ~ "]";
        
        #get the value from the Gear OR the contact tree (each element is in one or the other but not both)
        var compression_ft_trimmed=getprop ( "/fdm/jsbsim/gear/" ~unitName~"/compression-ft" );
        if (compression_ft_trimmed==nil or compression_ft_trimmed==0 ) compression_ft_trimmed=getprop ( "/fdm/jsbsim/contact/" ~unitName~"/compression-ft" );
        if (compression_ft_trimmed==nil) compression_ft_trimmed=0;
        if (compression_ft_trimmed<min) compression_ft_trimmed=min;
        if (compression_ft_trimmed>max) compression_ft_trimmed=max;        
        setprop("/environment/terrain-info/gear/"~unitName~"/compression-ft-trimmed", compression_ft_trimmed);
        
        # dust effects look pathetic if the number per second gets too pathetically low
        if (compression_ft_trimmed<zero_round ) compression_ft_trimmed=0;
        if (compression_ft_trimmed<low_limit and compression_ft_trimmed>0 ) compression_ft_trimmed=low_limit;
        var wake_dust_factor=compression_ft_trimmed*multiplier;
        setprop("/environment/terrain-info/gear/"~unitName~"/wake-dust-factor", wake_dust_factor);     
     }
}



var setCrash= func {
 var crashed = getprop("/fdm/jsbsim/systems/crash-detect/crashed");
 if (!crashed) return;
 
 #only do this if we've been un-crashed for at least 3 seconds
 var setCrash_thisPause_systime=systime();
 #print ("Crash: Time diff:", setCrash_thisPause_systime, " ", setCrash_lastPause_systime);
 var timeSinceLastCrash = setCrash_thisPause_systime - setCrash_lastPause_systime;
 setCrash_lastPause_systime=setCrash_thisPause_systime;
 if ( timeSinceLastCrash < 3 ) return;
 
 var  crashCause = "Airplane crashed ";
 var impact = getprop("/fdm/jsbsim/systems/crash-detect/impact");
 var impact_water = getprop("/fdm/jsbsim/systems/crash-detect/impact-water");
 var over_g = getprop("/fdm/jsbsim/systems/crash-detect/over-g");
 var current_g = getprop("/fdm/jsbsim/accelerations/Nz"); 
 
 if (impact) crashCause ~=" - Ground impact ";
 if (impact_water) {
     crashCause ~=" - Water impact ";
     #Ok, this doesnt' work rem-ing it out.
     #sink(10, .1, .5);
 }   
 if (over_g) crashCause ~= sprintf( " - G force %1.1f G exceeded 15G, aircraft destroyed ", current_g);
 
 #freeze/pause/crash
 #setprop ("/sim/freeze/clock", 1);
 #setprop ("/sim/freeze/master", 1);

 camel.dialog.init(450, 0, crashCause); camel.dialog.create(crashCause);

 setprop ("/sim/crashed", 1);

}

#sinks the ship, glug . . . glug . . . glug
# OK, it doesn't work bec. JSBSim keeps putting the craft on top of the surface again.
var sink = func (distance_ft, rate_ft_per_cycle, time_sec) {
 setprop ("/position/altitude-ft", getprop ("/position/altitude-ft") - rate_ft_per_cycle);
 distance_ft-=rate_ft_per_cycle;
 if (distance_ft<0) return;
 settimer ( func { sink (distance_ft,rate_ft_per_cycle, time_sec) }, time_sec);

}

friction_init();
var terrain_survol_loopid=getprop("/environment/terrain-info/terrain_servol_loopid");
if (terrain_survol_loopid==nil) terrain_survol_loopid=0;
terrain_survol_loopid+=1;
setprop("/environment/terrain-info/terrain_servol_loopid", terrain_survol_loopid);
terrain_survol(terrain_survol_loopid);  

restore_throttle = func  { 
    setprop("/controls/engines/engine/throttle", camel.throttle_save);
}    



#removelistener(list1);
var setCrash_lastPause_systime=systime();
var list1 = setlistener ( "/fdm/jsbsim/systems/crash-detect/crashed", func { setCrash() },0,0 );

# JSBSim cranks the engines a lot of times before it finally starts
# This is unrealistic for the Camel.  It either starts instantly or 
# not at all.  The following listener implements that functionality.
camel.throttle_save=0;
var list2 = setlistener ( "/engines/engine/cranking", func {
     # if the engines are cranking and it will start the engines
     # immediately 3 out of 4 times, if at least one magneto is on 
       if (getprop("/engines/engine/cranking")  
           and getprop("/controls/engines/engine/starter") 
           and rand() < .75
           and getprop("/controls/engines/engine/magnetos") > 0 ) {
         settimer ( func { 
               if (getprop("/engines/engine/cranking") and getprop("/controls/engines/engine/starter"))
                 camel.throttle_save = getprop("/controls/engines/engine/throttle"); 
                 setprop("/controls/engines/engine/throttle", 0);
                 setprop("/fdm/jsbsim/propulsion/set-running", -1);
                 settimer ( restore_throttle, 1.5);  
         }, 1); 
       } else {
         settimer ( func { setprop("/controls/engines/engine/starter", 0); }, .95);
       }     
     }  
  ,0,0 );


#When the camel goes upside down, its engine runs out of fuel after a while
#according to Over-Burdening the Camel.png, during a slow roll (23 seconds) 
# the engine stops about the time 90 degrees roll is achieved and starts 
# again about the time level flight is re-attained.h 
camel.prev_pilot_g=0;
camel.fuel_reserve=7;
camel.inverted_out_of_fuel=0;

#number of seconds of fuel before the carbeurator runs out in inverted flight/negative Gs 
camel.fuel_reserve_amount=7;
camel.upper_sputter=.6*camel.fuel_reserve_amount;
camel.upper_sputter_diff=camel.fuel_reserve_amount - camel.upper_sputter; 
camel.lower_sputter=.4*camel.fuel_reserve_amount;

var list3 = setlistener ( "/accelerations/pilot-gdamped", func {
     # if the engines are cranking and it will start the engines
     # immediately once out of 3 times, if at least one magneto is on
       camel.curr_pilot_g=getprop("/accelerations/pilot-gdamped");
       var time_elapsed=getprop("/sim/time/delta-sec");
       if (camel.curr_pilot_g>=.3) {
          camel.fuel_reserve += time_elapsed;
          #print ("Camel: Fuel Reserve - " , camel.fuel_reserve);
          if ( camel.fuel_reserve > camel.fuel_reserve_amount )
              camel.fuel_reserve = camel.fuel_reserve_amount;
       } else if ( camel.curr_pilot_g<=.1 ) {
          camel.fuel_reserve -= time_elapsed;
          #print ("Camel: Fuel Reserve - " , camel.fuel_reserve);
          if ( camel.fuel_reserve < 0 )
              camel.fuel_reserve = 0;
       
       }                 
       if (camel.fuel_reserve >= camel.fuel_reserve_amount and 
          camel.inverted_out_of_fuel==1) {  
           
           camel.magneto.updateMagnetos();
           camel.inverted_out_of_fuel=0;
           #print ("Camel: Un-inverted, blipping engine back on");
           #print ( camel.curr_pilot_g);
           #print (camel.prev_pilot_g); 
            
       } else if (camel.fuel_reserve <= 0 and 
          camel.inverted_out_of_fuel==0) {
           #print ("Camel: Inverted, blipping engine off");
           #print (camel.curr_pilot_g);
           #print (camel.prev_pilot_g);
           camel.magneto.magnetos.setValue(0);
           camel.inverted_out_of_fuel=1;
         
       # the next two cases make the engine sputter gradually off 
       # if the carb is just running out of fuel or sputter gradually
       # back on if it is just getting fuel back
       # This uses the magneto class in models/camel-utils.nas to turn
       # the magnetos off or turn them back on (to the state indicated 
       # by the two magneto switches)                              
       } else if (camel.fuel_reserve > camel.upper_sputter and 
          camel.inverted_out_of_fuel==1 and (rand() < time_elapsed*20)) {
           if (rand()> (camel.fuel_reserve - camel.upper_sputter)/camel.upper_sputter_diff) 
               camel.magneto.magnetos.setValue(0);
            else camel.magneto.updateMagnetos();
            #print ("Camel: Sputtering off");
       }  else if (camel.fuel_reserve < camel.lower_sputter and 
          camel.inverted_out_of_fuel==0 and (rand() < time_elapsed*20)) {
           if (rand()< (camel.fuel_reserve/camel.lower_sputter) )
               camel.magneto.updateMagnetos();
           else camel.magneto.magnetos.setValue(0);
           #print ("Camel: Sputtering on");         
       }     
       
       camel.prev_pilot_g=camel.curr_pilot_g;
           
     }  
  ,0,0 );
  






