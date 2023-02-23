import math


def format_float(x, precision=4):
    if math.isnan(x) or math.isinf(x):
        return f"{x}"
    elif math.isclose(x, round(x)):
        return f"{x:.1f}".rstrip('0')
    elif 1e-4 < x < 1e5:
        return f"{x:.{precision}f}".rstrip('0')
    else:
        return f"{x:.{precision}g}"
