package edu.uwb.braingrid.data.script;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.regex.Matcher;

/**
 * Provides support for building simple bash scripts in java where it is
 * anticipated that the script will automatically record provenance and
 * execution output to files. Provenance support includes the time that commands
 * began execution, ended execution, and their state when execution completed.
 *
 * Created by Nathan on 7/16/2014; Updated by Del on 7/23/2014
 *
 * @author Nathan Duncan
 * @version 0.1
 * @since 0.1
 */
public class Script {

    // <editor-fold defaultstate="collapsed" desc="Members">
    /* model data */
    private String bashScript;
    private final List<String> bashStatements;
    private final List<String> bashArgNames;
    private final List<String> bashArgDeclarations;
    private final List<String> usageStatements;
    /* persist validation flag */
    private boolean bashScriptConstructed;
    /* temporary variables */
    private StringBuilder sb;
    /* version information */
    private String version;

    /**
     * Prefix text for the echo of a command
     */
    public static final String commandText = "command";
    /**
     * Prefix text for milliseconds since epoch when a command was executed
     */
    public static final String startTimeText = "time started";
    /**
     * Prefix text for milliseconds since epoch when an executed command
     * completed
     */
    public static final String completedTimeText = "time completed";
    /**
     * Prefix text for the exit status of an executed command
     */
    public static final String exitStatusText = "exit status";
    /**
     * Prefix text for the version of the executed script
     */
    public static final String versionText = "version";
    /**
     * redirect file for script-related provenance information
     */
    public static final String printfOutputFilename = "prov.txt";
    /**
     * redirect file for std-err and std-out of executed commands
     */
    public static final String commandOutputFilename = "output.txt";
    /**
     * redirect file for git commit key
     */
    public static final String SHA1KeyFilename = "SHA1Key.txt";
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="Construction">
    /**
     * Constructs Script object and initializes members
     */
    public Script() {
        bashScript = "";
        bashStatements = new ArrayList<>();
        bashArgNames = new ArrayList<>();
        bashArgDeclarations = new ArrayList<>();
        usageStatements = new ArrayList<>();
        bashScriptConstructed = false;
        version = null;
    }

    /**
     * Constructs Script object and initializes members. In addition to the
     * default constructor, the version of the script is set. The version is
     * generally incremental and should follow the previous version of the
     * script where the first script version is "1".
     *
     * @param ver - the iteration of persisted scripts for the project
     */
    public Script(String ver) {
        this();
        version = ver;
    }
    // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="Data Manipulation">
    /**
     * Shortcut helper function, to be used when all args are not variable and
     * thus there are no corresponding usage statements
     *
     * @param filename name of the file to execute from this script
     * @param args - arguments to provide for execution. Even for variable
     * arguments this is necessary because the names are used in the usage for
     * the script.
     * @param fromWrkDir
     * @return true if the program execution statement was added to the script
     * model correctly, otherwise false
     */
    public boolean executeProgram(String filename, String[] args, boolean fromWrkDir) {
        boolean[] variable = new boolean[args.length];
        String[] addToUsage = new String[args.length];
        for (int i = 0, im = args.length; i < im; i++) {
            variable[i] = false;
            addToUsage[i] = "";
        }
        return executeProgram(filename, args, variable, addToUsage, fromWrkDir);
    }

    /**
     * Executes a program without ./ such as cd or mkdir or ls, etc.
     *
     * @param filename name of the file to execute from this script
     * @param args - arguments to provide for execution. Even for variable
     * arguments this is necessary because the names are used in the usage for
     * the script.
     * @return true if the program execution statement was added to the script
     * model correctly, otherwise false
     */
    public boolean executeProgram(String filename, String[] args) {
        return executeProgram(filename, args, false);
    }

    /**
     * Executes a given program with the provided arguments. Some of the
     * arguments may be variable. Whether or not they are variable is determined
     * by the boolean value at the corresponding position in variable parameter.
     * A description of each variable should be provided.
     *
     * Note: The length of args, variable, and addToUsage must be the same.
     *
     * @param filename name of the file to execute
     * @param args - arguments to provide for execution. Even for variable
     * arguments this is necessary because the names are used in the usage for
     * the script.
     * @param variable - whether or not each argument should be script variable
     * @param addToUsage - explanation of each argument. (The usage explanation
     * for non-variable args will not be used, but must be specified or null as
     * the length of addToUsage must match the args and variable parameters)
     * @param fromWrkDir - Indicates whether or not the command execution should
     * be prefaced with a symbolic link to the current working directory.
     * @return True if the command was successfully added to the script,
     * otherwise false
     */
    public boolean executeProgram(String filename, String[] args,
            boolean[] variable, String[] addToUsage, boolean fromWrkDir) {
        boolean success1;//, success2 = true;
        success1 = executeProgramForBash(filename, args,
                variable, addToUsage, fromWrkDir);
        //success2 = executeProgramForBatch(filename, args, variable, addToUsage);
        return success1;// && success2;
    }

    /**
     * Executes a given program with the provided arguments. Some of the
     * arguments may be variable. Whether or not they are variable is determined
     * by the boolean value at the corresponding position in variable parameter.
     * A description of each variable should be provided.
     *
     * Note: The length of args, variable, and addToUsage must be the same.
     *
     * @param filename name of the file to execute
     * @param args - arguments to provide for execution. Even for variable
     * arguments this is necessary because the names are used in the usage for
     * the script.
     * @param variable - whether or not each argument should be script variable
     * @param addToUsage - explanation of each argument. (The usage explanation
     * for non-variable args will not be used, but must be specified or null as
     * the length of addToUsage must match the args and variable parameters)
     * @param fromWrkDir - Indicates whether or not the command execution should
     * be prefaced with a symbolic link to the current working directory.
     * @return True if the command was successfully added to the script,
     * otherwise false
     */
    private boolean executeProgramForBash(String filename, String[] args,
            boolean[] variable, String[] addToUsage, boolean fromWrkDir) {
        String dotSlash = fromWrkDir ? "./" : "";
        boolean success = true;
        if (args.length == variable.length && args.length == addToUsage.length) {
            sb = new StringBuilder();
            sb.append(dotSlash).append(filename).append(' ');
            for (int i = 0, im = args.length; i < im; i++) {
                if (i != 0) {
                    sb.append(' ');
                }
                if (variable[i]) {
                    bashArgNames.add(args[i]);
                    bashArgDeclarations.add(new StringBuilder("arg").
                            append(bashArgDeclarations.size() + 1).append("=$").
                            append(bashArgDeclarations.size() + 1).
                            toString());
                    usageStatements.add(addToUsage[i]);

                    sb.append("\"$arg").
                            append(bashArgDeclarations.size()).append("\"");
                } else {
                    sb.append('\"').append(args[i]).append("\"");
                }
            }
            preCommandOutput(sb.toString(), !bashStatements.isEmpty());
            sb.append(" >");
            if (!bashStatements.isEmpty()) {
                sb.append('>');
            }
            sb.append(" ~/output.txt");
            sb.append(" 2>");
            if (!bashStatements.isEmpty()) {
                sb.append(">");
            }
            sb.append(" ~/output.txt");
            bashStatements.add(sb.toString());
            postCommandOutput(!bashStatements.isEmpty());
        } else {
            success = false;
        }
        return success;
    }

    /**
     * Adds a printf statement to the script. The argument to printf is composed
     * of: prefix: statement
     *
     * @param prefix - the prefix used to identify the statement during analysis
     * @param statement - the statement indicating the value associated with the
     * prefix
     * @param provFile
     * @param append - True if the redirected standard out descriptor and
     * standard error descriptor should be appended to, False if they should be
     * overwritten by the output of this printf statement
     */
    public void printf(String prefix, String statement, String provFile, boolean append) {
        statement = printfEscape(statement);
        if (provFile == null) {
            provFile = Script.printfOutputFilename;
        }
        StringBuilder s = new StringBuilder();
        String outToken = append ? ">>" : ">";
        s.append("printf \"").append(prefix).append(": ").append(statement).append("\\n\" ").
                append(outToken).append(" ~/").append(provFile).append(" 2").
                append(outToken).append(" ~/").append(provFile);
        bashStatements.add(s.toString());
    }

    /**
     * Adds a command statement to the script irrespective of script variables
     *
     * @param stmt
     * @param outputFile - File to redirect standard error/out to
     * @param append - Whether or not the output file should be appended to.
     * Note: Since any file name, previously used or not, can be specified as
     * the output file, this function has no safe-guards against overwriting
     * previous redirected output. If the file has been previously used in the
     * script, but isn't appended to in future uses, it will be overwritten. On
     * the other hand, if the file is used as a redirect for the first time in
     * the script and it is appended to, the file may contain output from
     * previous execution of the script.
     */
    public void addVerbatimStatement(String stmt, String outputFile, boolean append) {
        //stmt = printfEscape(stmt);
        if (outputFile == null) {
            outputFile = "~/output.txt";
        }
        preCommandOutput(stmt, !bashStatements.isEmpty());
        String redirectString = (append ? " >>" : " >") + " " + outputFile
                + " 2>> " + outputFile;
        bashStatements.add(stmt + redirectString);
        postCommandOutput(!bashStatements.isEmpty());
    }

    public static String printfEscape(String s) {
        return s.replaceAll("\\Q\\a\\E", Matcher.quoteReplacement("\\\\\\a")).
                replaceAll("\\Q\\b\\E", Matcher.quoteReplacement("\\\\\\b")).
                replaceAll("\\Q\\c\\E", Matcher.quoteReplacement("\\\\\\c")).
                replaceAll("\\Q\\d\\E", Matcher.quoteReplacement("\\\\\\d")).
                replaceAll("\\Q\\e\\E", Matcher.quoteReplacement("\\\\\\e")).
                replaceAll("\\Q\\f\\E", Matcher.quoteReplacement("\\\\\\f")).
                replaceAll("\\Q\\n\\E", Matcher.quoteReplacement("\\\\\\n")).
                replaceAll("\\Q\\r\\E", Matcher.quoteReplacement("\\\\\\r")).
                replaceAll("\\Q\\t\\E", Matcher.quoteReplacement("\\\\\\t")).
                replaceAll("\\Q\\v\\E", Matcher.quoteReplacement("\\\\\\v")).
                replaceAll("\\Q%\\E", Matcher.quoteReplacement("%%")).
                replaceAll("\\Q\\'\\E", Matcher.quoteReplacement("\\\\'")).
                replaceAll("\\Q\\\"\\E", Matcher.quoteReplacement("\\\\\""));
    }

    private void preCommandOutput(String whatStarted, boolean append) {
        whatStarted = printfEscape(whatStarted);
        StringBuilder s = new StringBuilder();
        String outToken;
        outToken = append ? ">>" : ">";
        s.append("printf \"command: ").append(whatStarted.replaceAll("\"", "")).
                append("\\ntime started: `date +%s`\\n\" ").
                append(outToken).append(" ~/prov.txt").append(" 2").
                append(outToken).append(" ~/prov.txt");
        bashStatements.add(s.toString());
    }

    private void postCommandOutput(boolean append) {
        StringBuilder s = new StringBuilder();
        String outToken;
        outToken = append ? ">>" : ">";
        s.append("printf \"exit status: $?\\ntime completed: `date +%s`\\n\" ").
                append(outToken).append(" ~/prov.txt").append(" 2").
                append(outToken).append(" ~/prov.txt");
        bashStatements.add(s.toString());
    }

    /**
     * Constructs both the bash and batch scripts
     *
     * @return true if the script was constructed successfully, otherwise false
     */
    public boolean construct() {
        bashScriptConstructed = constructBashScript();
        //batchScriptConstructed = constructBatchScript();
        return bashScriptConstructed;
    }

    /**
     * Constructs the batch script from the previously constructed parts see
     * model data declarations
     */
    private boolean constructBashScript() {
        StringBuilder builder = new StringBuilder();
        builder.append("#!/bin/bash").append('\n');
        builder.append("# script created on: ").append((new Date()).toString()).
                append("\n\n");
        // specify command line arguments as variables
        for (int i = 0, im = bashArgDeclarations.size(); i < im; i++) {
            builder.append(bashArgDeclarations.get(i)).append('\n');
        }
        // check arguments given
        builder.append('\n').
                // begin if
                append("if [ \"$#\" -ne ").
                append(bashArgDeclarations.size()).
                append(" ]; then\n").
                append("\techo \"wrong number of arguments. expected ").
                append(bashArgDeclarations.size()).append("\"\n");
        // provide usage
        builder.append("\techo \"usage: ").append(" ${0##*/}");
        for (int i = 0, im = bashArgNames.size(); i < im; i++) {
            builder.append(" <").append(bashArgNames.get(i)).append('>');
        }
        builder.append("\"\n");
        for (int i = 0, im = usageStatements.size(); i < im; i++) {
            builder.append("\techo \"").append(i + 1).append('.').append('<').
                    append(bashArgNames.get(i)).append('>').append(':').
                    append(usageStatements.get(i)).append("\"\n");
        }
        // exit
        builder.append("exit 1\n").
                // end if
                append("fi\n").append("\n");
        // run the programs with the given arguments
        for (int i = 0, im = bashStatements.size(); i < im; i++) {
            builder.append(bashStatements.get(i)).append('\n');
        }
        bashScript = builder.toString();
        // set flag for persistence         
        return bashScriptConstructed = true;
    } // </editor-fold>

    // <editor-fold defaultstate="collapsed" desc="Persistence">
    /**
     * Writes the script to disk. The script must be constructed prior to being
     * persisted.
     *
     * @param filePathWithBaseName - The relative, absolute, or canonical path
     * to the file that will contain the script data, without the file extension
     * @return True if both the bash script and batch script were persisted
     * successfully, otherwise false
     */
    public boolean persist(String filePathWithBaseName) {
        boolean bashScriptPersisted = false;
        if (bashScriptConstructed) {
            bashScriptPersisted
                    = persistBashScript(filePathWithBaseName + ".sh");
        }
        return bashScriptPersisted;
    }

    /**
     * Writes the script to disk as a bash script. The script must be
     * constructed by calling the construct function prior to being persisted.
     *
     * @param filePath - The relative, absolute, or canonical path to the file
     * that will contain the script data
     * @return True if the bash script was persisted successfully, otherwise
     * false.
     */
    public boolean persistBashScript(String filePath) {
        boolean success = true;
        File scriptFile = new File(filePath);
        try (FileWriter scriptWriter = new FileWriter(scriptFile, false)) {
            scriptWriter.write(bashScript);
        } catch (IOException e) {
            success = false;
        }
        return success;
    }

    /**
     * Determines the last name of a script persisted with a given version
     * number
     *
     * @param version The version of the script persisted
     * @return The last name of the script without any directories
     */
    public static String getFilename(int version) {
        return "run_v" + version + ".sh";
    }
    // </editor-fold>
}
