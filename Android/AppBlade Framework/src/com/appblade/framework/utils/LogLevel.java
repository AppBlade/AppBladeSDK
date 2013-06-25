package com.appblade.framework.utils;

/**
 * <li>{@link LogLevel.DEBUG} Show all debug- and verbose-level logs
 * <li>{@link LogLevel.ERRORS} Show all error-level logs
 * <li>{@link LogLevel.WARNINGS} Show all warning-level logs
 * <li>{@link LogLevel.ALL} Show all logs.
 * <li>{@link LogLevel.NONE} Default. Don't show any logs.
 * @author andrewtremblay
 */
public class LogLevel {
	public static final int VERBOSE = Integer.parseInt("00001", 2);
    public static final int DEBUG = Integer.parseInt("00010", 2);
    public static final int INFO = Integer.parseInt("00100");
    public static final int WARNINGS = Integer.parseInt("01000", 2);
    public static final int ERRORS = Integer.parseInt("10000", 2);
    public static final int ALL = VERBOSE | DEBUG | INFO | WARNINGS | ERRORS;
	public static final int NONE = 0;
}
