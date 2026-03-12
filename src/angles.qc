//
// angles.qc
//
// Functions for doing angle/vector calculations
//
// Fields used:
//
//
// All code by Paul Baker unless otherwise commented.
//

//
//   P I C K  A N G L E
//
//   Given two angles, and a percent, this function returns a new angle
//   that is some percent closer to angle2 from angle1.
//
//   example: angle1 is the current angle, angle2 is where you want to be,
//            based on the percent, the returned angle will be a new
//            angle inbetween angle1 and angle2.  The higher the percent,
//            the closer the returned angle will be to angle2.
//
//   JP - removed commented code and optimized slightly
//
float (float angle1, float angle2, float percent) angles_pick_angle =
{
	local float difference;
		
	difference = angle2 - angle1;			// how far apart angles are

	if (difference > 180)
		difference = difference - 360;
	else if (difference <= -180)
		difference = difference + 360;

	return angle1 + difference * percent; 
	
};

//
//  B E S T A I M
//     by Paul Baker
//  Returns desired aim 'from' one position 'to' another
//
//  Recommented and Recoded by JP
//
//  Dealing with pitch is a bit tricky.  vectoangles returns a pitch in [0, 360] where
//  0 is looking straight ahead, 45 looks up at 45 and 315 looks down at 45\xB0.
//  However, the pitch in v_angle is in the range [-68, 78] where positive is *down*
//  and negative is up.
//

vector (vector from, vector to) angles_bestaim =
{
	local vector bestaim;
	bestaim = vectoangles(to - from);
	if (bestaim_x > 270)
	{
		// Looking down; convert angle for v_angle and clamp
		bestaim_x = 360 - bestaim_x;
		if (bestaim_x > 78)
			bestaim_x = 78;
	}
	else
	{
		// Looking up; convert angle for v_angle and clamp
		bestaim_x = 0 - bestaim_x;
		if (bestaim_x < -68)
			bestaim_x = -68;
	}

	return bestaim;
};

// CRMOD
//  F I X A N G L E
//    by Paul Baker
//
//  Sends new view angle to client and stores the value in .crmod_oldangle for use in angle smoothing
//

void(vector v) angles_fixangle =
{
	self.clanring_oldangle = v;
	// Set the new angles.  The 0.1 angles are subtracted to ensure
    // that self.angles will get rounded off to angle (which was obtained
    // by rounding off self.movetarget.v_angles).  Don't ask me why you
    // have to subtract; logic dictates that you should be adding.  But
    // I tried adding and it didn't work; I tried subtracting and it did.
    // Take it up with id.
	self.v_angle = self.angles = v - '0.1 0.1 0';
	if (isFTEserver)
		self.fixangle = 3;	// 3 = FTE Skip Deltas.
	else
		self.fixangle = TRUE;	// forces client's angle to the above, using svc_setangle.
};
