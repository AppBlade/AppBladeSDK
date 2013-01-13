package com.appblade.framework.stats;

import java.util.List;

/**
 * Interface for defining behavior after we've gotten a list of session data (I'd suggest POSTing it). 
 * @author andrew.tremblay@raizlabs
 */
public interface OnSessionDataAcquiredListener {
	public void OnSessionDataAcquired(List<SessionData> acquiredData);
}
