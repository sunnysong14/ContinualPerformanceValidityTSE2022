from math import ceil


def days_2_timestamps(days):
    """
    convert the days to #timestamps
    NOTE Not work for array

    Liyan Song Nov. 2019
    """

    timestamps_in_1day = 86400
    timestamps_of_days = ceil(days * timestamps_in_1day)
    return timestamps_of_days
