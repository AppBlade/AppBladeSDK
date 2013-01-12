package com.appblade.framework.feedback;

/**
 * Interface for notifying when data for feedback is ready. (grabbing screenshots can take a while)
 * @author andrew.tremblay@raizlabs
 */
public interface OnFeedbackDataAcquiredListener {
	public void OnFeedbackDataAcquired(FeedbackData data);
}
