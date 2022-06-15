#!/usr/bin/awk


BEGIN {
    title = "TERMINAL BALLISTICS"

    # a = angle, v = velocity, w = wind speed, g = gravity
    #CONSTS
    g = 10
    max_wind = 20
    max_v = 100
    max_a = 90

    #LOAD OBJECT SPRITES
    objs[0] = "tank1"; objs[1] = "tank2"; objs[2] = "expl";
    for(oi in objs){
        while(getline < ("sprites/" objs[oi] ".txt") > 0)
            temp[c++] = $0
		for(i in temp){
			j = length(temp) - 1 - i
			sprites[objs[oi]][j] = temp[i]
		}
		delete temp; c = 0;
    }
   
    #INIT MAP BORDER
    init_border()

    init_game()
}

#                USER INPUT
########################################################

#Quit
/(q|Q)/ {exit}

#Restart
/(r|R)/ {init_game()}

#Get Angle
turn_phase == 0{
	if($1 < 0 || $1 > max_a) next
	a = $1 * 3.1415 / 180 # deg -> rad
	if(on_turn == 1) a *= -1
	print "Enter velocity (0 - " max_v "):"

}

#Get Velocity
turn_phase == 1{
	if($1 < 0 || $1 > max_v) next
	v = $1
	#CHECK HIT
	get_range(-muzzle_y, x_arr)
	hit_x = muzzle_x + x_arr[1] * 2
	pos["expl", "x"] = hit_x - length(sprites["expl"][0]) / 2
	
	if(hit_x >= pos[opponent, "x"] && hit_x <= pos[opponent, "x"] + length(sprites[opponent][0]))
		score[on_turn]++

	render()
	print "Next turn"
}

#End Turn
turn_phase == 2 {next_player()}

#Next Phase
{turn_phase = ++turn_phase % 3}



#                     FUNCTIONS
########################################################


function init_game(){

    #INIT OBJECT POSITIONS
    pos["tank1", "x"] = 6; pos["tank1", "y"] = 0; pos["tank1", "z"] = 1;
    pos["tank2", "x"] = screen_w - length(sprites["tank2"][0]) - pos["tank1", "x"]; pos["tank2", "y"] = 0; pos["tank2", "z"] = 1;
    pos["expl", "x"] = 50;  pos["expl", "y"] = 0; pos["expl", "z"] = 2;

    #SORT OBJS BY Z
    asort(objs, z_order, "sort_by_z")

    srand()
    score[0] = 0; score[1] = 0
    on_turn = -1
    turn_phase = 0
    next_player()
}



function next_player(){

	w = rand() * max_wind - (max_wind / 2)
	on_turn = (on_turn + 1) % 2
	playing = objs[on_turn]
	opponent = objs[(on_turn + 1) % 2]
	muzzle_x = pos[playing, "x"] + (1 - on_turn) * (length(sprites[playing][0]) - 1)
	muzzle_y = pos[playing, "y"] + length(sprites[playing]) - 1
	pos["expl", "x"] = screen_w 

	render()
	print "Player" on_turn + 1 "'s turn. (Q)uit, (R)estart" 
	print "Enter angle (0° - " max_a "°):"
}


function render(){

	for(h = screen_h - 1; h >= 0; h--){

		line = sprites["border"][h]

		if(turn_phase == 1){
			get_range(h - muzzle_y, x_arr)
			for(i in x_arr)
				line = insert(line, ".", x_arr[i] * 2 + muzzle_x)
		}
		for(oi in z_order){
			obj = z_order[oi]; line_num = h - pos[obj, "y"]
			if(line_num in sprites[obj])
				line = insert(line, sprites[obj][line_num], pos[obj, "x"])
		}
		if(h == screen_h - 3){
			wind_msg = wind_speed_msg()
			line = insert(line, wind_msg, length(line) / 2 - length(wind_msg) / 2)
			line = insert(line, "SCORE 1: " score[0], 6)
			line = insert(line, "SCORE 2: " score[1], length(line) - 17)
		}
		print line
	}
}


function get_range(y, x_arr){

	delete x_arr
	d = (v * sin(a) * v * sin(a)) - (2 * g * y)
        if(d < 0)
		return
        t1 = ((v * sin(a)) + sqrt(d)) / g
	t2 = ((v * sin(a)) - sqrt(d)) / g
	x_arr[1] = v * cos(a) * t1 + (w / 2) * (t1 * t1)
	x_arr[2] = v * cos(a) * t2 + (w / 2) * (t2 * t2)
	if(on_turn == 0) asort(x_arr, x_arr, "@val_num_desc")
	else if (on_turn == 1) asort(x_arr, x_arr, "@val_num_asc")
}


function sort_by_z(i1, v1, i2, v2){

	z1 = pos[v1, "z"]; z2 = pos[v2, "z"]; 
	if(z1 < z2) return -1; if(z1 == z2) return 0; return 1;
}


function insert(line, sprite, pos){

	part_1 = substr(line, 1, pos)
	part_2 = substr(sprite, -pos + 1)
	part_3 = substr(line, pos + length(sprite) + 1)
	return substr(part_1 part_2 part_3, 1, screen_w)
}

function string_of(symbol, l){

	for(res = ""; length(res) < l * length(symbol); res = res symbol);
	return res
}


function init_border(){

	"tput cols" | getline screen_w
    "expr $(tput lines) - 5" | getline screen_h

	sprites["border"][0] = "\\" string_of("_", screen_w - 2) "/"  	

	for(h = 1; h < screen_h - 1; h++)
		sprites["border"][h] = "|" string_of(" ", screen_w - 2) "|" 
	
	titleLine = "+" string_of("-", screen_w - 2) "+" 
	sprites["border"][screen_h - 1] = insert(titleLine, title, (length(titleLine) - length(title)) / 2)
}

function wind_speed_msg(){

	if(w > 0){arrow = "≈>"; n = int(w)}
	else if(w < 0) {arrow = "<≈"; n = -int(w)}
	else {arrow = " "; n = 0}
	return string_of(arrow, n + 1) " WIND: " w " " string_of(arrow, n + 1)
}



