package org.antlr.test;

import org.antlr.test.unit.TestSuite;

public class TestTreeParsing extends TestSuite {
	public void testFlatList() throws Exception {
		String grammar =
			"grammar T;\n" +
			"options {output=AST;}\n" +
			"a : ID INT;\n" +
			"ID : 'a'..'z'+ ;\n" +
			"INT : '0'..'9'+;\n" +
			"WS : (' '|'\\n') {channel=99;} ;\n";

		String treeGrammar =
			"tree grammar TP;\n" +
			"a : ID INT\n" +
			"    {System.out.println($ID+\", \"+$INT);}\n" +
			"  ;\n";

		String found =
			TestCompileAndExecSupport.execTreeParser("t.g",
													 grammar,
													 "T",
													 "tp.g",
													 treeGrammar,
													 "TP",
													 "TLexer",
												 	 "a",
													 "a",
													 "abc 34");
		String expecting = "abc, 34\n";
		assertEqual(found, expecting);
	}

	public void testSimpleTree() throws Exception {
		String grammar =
			"grammar T;\n" +
			"options {output=AST;}\n" +
			"a : ID INT -> ^(ID INT);\n" +
			"ID : 'a'..'z'+ ;\n" +
			"INT : '0'..'9'+;\n" +
			"WS : (' '|'\\n') {channel=99;} ;\n";

		String treeGrammar =
			"tree grammar TP;\n" +
			"a : ^(ID INT)\n" +
			"    {System.out.println($ID+\", \"+$INT);}\n" +
			"  ;\n";

		String found =
			TestCompileAndExecSupport.execTreeParser("t.g",
													 grammar,
													 "T",
													 "tp.g",
													 treeGrammar,
													 "TP",
													 "TLexer",
												 	 "a",
													 "a",
													 "abc 34");
		String expecting = "abc, 34\n";
		assertEqual(found, expecting);
	}

	public void testFlatVsTreeDecision() throws Exception {
		String grammar =
			"grammar T;\n" +
			"options {output=AST;}\n" +
			"a : b c ;\n" +
			"b : ID INT -> ^(ID INT);\n" +
			"c : ID INT;\n" +
			"ID : 'a'..'z'+ ;\n" +
			"INT : '0'..'9'+;\n" +
			"WS : (' '|'\\n') {channel=99;} ;\n";

		String treeGrammar =
			"tree grammar TP;\n" +
			"a : b b ;\n" +
			"b : ID INT    {System.out.print($ID+\" \"+$INT);}\n" +
			"  | ^(ID INT) {System.out.print(\"^(\"+$ID+\" \"+$INT+')');}\n" +
			"  ;\n";

		String found =
			TestCompileAndExecSupport.execTreeParser("t.g",
													 grammar,
													 "T",
													 "tp.g",
													 treeGrammar,
													 "TP",
													 "TLexer",
												 	 "a",
													 "a",
													 "a 1 b 2");
		String expecting = "^(a 1)b 2\n";
		assertEqual(found, expecting);
	}

	public void testFlatVsTreeDecision2() throws Exception {
		String grammar =
			"grammar T;\n" +
			"options {output=AST;}\n" +
			"a : b c ;\n" +
			"b : ID INT+ -> ^(ID INT+);\n" +
			"c : ID INT+;\n" +
			"ID : 'a'..'z'+ ;\n" +
			"INT : '0'..'9'+;\n" +
			"WS : (' '|'\\n') {channel=99;} ;\n";

		String treeGrammar =
			"tree grammar TP;\n" +
			"a : b b ;\n" +
			"b : ID INT+    {System.out.print($ID+\" \"+$INT);}\n" +
			"  | ^(x=ID (y=INT)+) {System.out.print(\"^(\"+$x+' '+$y+')');}\n" +
			"  ;\n";

		String found =
			TestCompileAndExecSupport.execTreeParser("t.g",
													 grammar,
													 "T",
													 "tp.g",
													 treeGrammar,
													 "TP",
													 "TLexer",
												 	 "a",
													 "a",
													 "a 1 2 3 b 4 5");
		String expecting = "^(a 3)b 5\n";
		assertEqual(found, expecting);
	}

	public void testCyclicDFALookahead() throws Exception {
		String grammar =
			"grammar T;\n" +
			"options {output=AST;}\n" +
			"a : ID INT+ PERIOD;\n" +
			"ID : 'a'..'z'+ ;\n" +
			"INT : '0'..'9'+;\n" +
			"SEMI : ';' ;\n"+
			"PERIOD : '.' ;\n"+
			"WS : (' '|'\\n') {channel=99;} ;\n";

		String treeGrammar =
			"tree grammar TP;\n" +
			"a : ID INT+ PERIOD {System.out.print(\"alt 1\");}"+
			"  | ID INT+ SEMI   {System.out.print(\"alt 2\");}\n" +
			"  ;\n";

		String found =
			TestCompileAndExecSupport.execTreeParser("t.g",
													 grammar,
													 "T",
													 "tp.g",
													 treeGrammar,
													 "TP",
													 "TLexer",
												 	 "a",
													 "a",
													 "a 1 2 3.");
		String expecting = "alt 1\n";
		assertEqual(found, expecting);
	}

	public void testTemplateOutput() throws Exception {
		String grammar =
			"grammar T;\n" +
			"options {output=AST;}\n" +
			"a : ID INT;\n" +
			"ID : 'a'..'z'+ ;\n" +
			"INT : '0'..'9'+;\n" +
			"WS : (' '|'\\n') {channel=99;} ;\n";

		String treeGrammar =
			"tree grammar TP;\n" +
			"options {output=template; ASTLabelType=CommonTree;}\n" +
			"s : a {System.out.println($a.st);};\n" +
			"a : ID INT -> {new StringTemplate($INT.text)}\n" +
			"  ;\n";

		String found =
			TestCompileAndExecSupport.execTreeParser("t.g",
													 grammar,
													 "T",
													 "tp.g",
													 treeGrammar,
													 "TP",
													 "TLexer",
												 	 "a",
													 "s",
													 "abc 34");
		String expecting = "34\n";
		assertEqual(found, expecting);
	}

}
