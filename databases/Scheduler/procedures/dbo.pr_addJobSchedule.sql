CREATE PROC pr_addJobSchedule
(
	@nUkeyJobSchedule INT OUT,
	@RunAtInSecondsFromMidnight INT,
	@FrequencyType INT = 0,
	@Frequency INT = 1,
	@AbsoluteSubFrequency VARCHAR(100) = NULL,
	@MontlyRelativeSubFrequencyWhich INT = NULL,
	@MontlyRelativeSubFrequencyWhat INT = NULL
)
AS
	SELECT @nUkeyJobSchedule = -1

	INSERT INTO JobSchedules(FrequencyType, Frequency, AbsoluteSubFrequency, MontlyRelativeSubFrequencyWhich, MontlyRelativeSubFrequencyWhat, RunAtInSecondsFromMidnight)
	SELECT @FrequencyType, @Frequency, @AbsoluteSubFrequency, @MontlyRelativeSubFrequencyWhich, @MontlyRelativeSubFrequencyWhat, @RunAtInSecondsFromMidnight

	SELECT @nUkeyJobSchedule = SCOPE_IDENTITY()
GO
