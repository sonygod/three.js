package chevrotain;

import chevrotain.gast.GAstVisitor;
import chevrotain.gast.Rule;
import chevrotain.gast.Terminal;
import chevrotain.gast.Option;
import chevrotain.gast.Repetition;
import chevrotain.gast.RepetitionMandatory;
import chevrotain.gast.RepetitionMandatoryWithSeparator;
import chevrotain.gast.RepetitionWithSeparator;
import chevrotain.gast.NonTerminal;
import chevrotain.gast.Alternative;
import chevrotain.gast.Alternation;
import chevrotain.lexer.Lexer;
import chevrotain.lexer.LexerDefinitionErrorType;
import chevrotain.lexer.Token;
import chevrotain.lexer.IToken;
import chevrotain.parser.Parser;
import chevrotain.parser.ParserDefinitionErrorType;
import chevrotain.parser.EmbeddedActionsParser;
import chevrotain.parser.CstParser;
import chevrotain.parser.RecognitionException;
import chevrotain.parser.EarlyExitException;
import chevrotain.parser.MismatchedTokenException;
import chevrotain.parser.NotAllInputParsedException;
import chevrotain.parser.NoViableAltException;
import chevrotain.parser.ICstVisitor;
import chevrotain.parser.CstVisitorDefinitionError;
import chevrotain.parser.BaseSemanticVisitor;
import chevrotain.parser.BaseSemanticsWithDefaults;
import chevrotain.utils.Utils;
import chevrotain.utils.PerformanceTracer;
import chevrotain.utils.GastRecorder;
import chevrotain.utils.ContentAssist;
import chevrotain.utils.ErrorHandler;
import chevrotain.utils.RecognizerEngine;
import chevrotain.utils.LexerAdapter;
import chevrotain.utils.TreeBuilder;
import chevrotain.utils.LooksAhead;
import chevrotain.utils.Recoverable;
import chevrotain.utils.RecognizerApi;
import chevrotain.utils.GastRefResolverVisitor;
import chevrotain.utils.NextAfterTokenWalker;
import chevrotain.utils.NextTerminalAfterAtLeastOneWalker;
import chevrotain.utils.NextTerminalAfterAtLeastOneSepWalker;
import chevrotain.utils.NextTerminalAfterManyWalker;
import chevrotain.utils.NextTerminalAfterManySepWalker;
import chevrotain.utils.AbstractNextTerminalAfterProductionWalker;
import chevrotain.utils.AbstractNextPossibleTokensWalker;
import chevrotain.utils.LooksAheadSequenceFromAlternatives;
import chevrotain.utils.BuildLookaheadFuncForOr;
import chevrotain.utils.BuildLookaheadFuncForOptionalProd;
import chevrotain.utils.BuildAlternativesLookAheadFunc;
import chevrotain.utils.BuildSingleAlternativeLookaheadFunction;
import chevrotain.utils.GetLookaheadPathsForOr;
import chevrotain.utils.GetLookaheadPathsForOptionalProd;
import chevrotain.utils.ContainsPath;
import chevrotain.utils.IsStrictPrefixOfPath;
import chevrotain.utils.AreTokenCategoriesNotUsed;
import chevrotain.utils.CheckPrefixAlternativesAmbiguities;
import chevrotain.utils.ValidateSomeNonEmptyLookaheadPath;
import chevrotain.utils.ValidateTooManyAlts;
import chevrotain.utils.RepetionCollector;
import chevrotain.utils.ValidateAmbiguousAlternationAlternatives;
import chevrotain.utils.ValidateEmptyOrAlternative;
import chevrotain.utils.GetFirstNoneTerminal;
import chevrotain.utils.ValidateNoLeftRecursion;
import chevrotain.utils.ValidateRuleIsOverridden;
import chevrotain.utils.ValidateRuleDoesNotAlreadyExist;
import chevrotain.utils.OccurrenceValidationCollector;
import chevrotain.utils.IdentifyProductionForDuplicates;
import chevrotain.utils.ValidateGrammar;
import chevrotain.utils.ResolveGrammar;
import chevrotain.utils.PossiblePathsFrom;
import chevrotain.utils.NextPossibleTokensAfter;
import chevrotain.utils.SetNodeLocationFull;
import chevrotain.utils.SetNodeLocationOnlyOffset;
import chevrotain.utils.AddTerminalToCst;
import chevrotain.utils.AddNoneTerminalToCst;
import chevrotain.utils.FunctionAndInstanceName;
import chevrotain.utils.DefineNameProp;
import chevrotain.utils.ValidateVisitor;
import chevrotain.utils.CreateBaseVisitorConstructorWithDefaults;
import chevrotain.utils.CreateBaseSemanticVisitorConstructor;
import chevrotain.utils.DefaultVisit;
import chevrotain.utils.BuildInProdFollowPrefix;
import chevrotain.utils.BuildBetweenProdsFollowPrefix;
import chevrotain.utils.ComputeAllProdsFollows;
import chevrotain.utils.ResyncFollowsWalker;
import chevrotain.regexpToAst.RegExpParser;
import chevrotain.regexpToAst.BaseRegExpVisitor;
import chevrotain.regexpToAst.GetOptimizedStartCodesIndices;
import chevrotain.regexpToAst.FirstCharOptimizedIndices;
import chevrotain.regexpToAst.CanMatchCharCode;
import chevrotain.regexpToAst.FailedOptimizationPrefixMsg;
import chevrotain.regexpToAst.ClearRegExpParserCache;
import chevrotain.regexpToAst.GetRegExpAst;
import chevrotain.utils.ApplyMixins;
import chevrotain.utils.GetProdType;
import chevrotain.utils.KeyForAutomaticLookahead;
import chevrotain.utils.CreateSyntaxDiagramsCode;
import chevrotain.utils.SerializeGrammar;
import chevrotain.utils.SerializeProduction;
import chevrotain.utils.AttemptInRepetitionRecovery;

/**
 * The main entry point for the Chevrotain library.
 * This module re-exports all the classes and functions
 * that are part of the Chevrotain public API.
 */
class Chevrotain {

	public static get VERSION() : String {
		return "9.0.1";
	}

	public static get CstParser() : Class<CstParser> {
		return CstParser;
	}

	public static get EmbeddedActionsParser() : Class<EmbeddedActionsParser> {
		return EmbeddedActionsParser;
	}

	public static get ParserDefinitionErrorType() : Enum<ParserDefinitionErrorType> {
		return ParserDefinitionErrorType;
	}

	public static get EMPTY_ALT() : () -> Void {
		return EMPTY_ALT;
	}

	public static get Lexer() : Class<Lexer> {
		return Lexer;
	}

	public static get LexerDefinitionErrorType() : Enum<LexerDefinitionErrorType> {
		return LexerDefinitionErrorType;
	}

	public static get createToken() : (t : {pattern : Dynamic<Any>, name : String, parent? : Dynamic<Any>, categories? : Dynamic<Any>, label? : Dynamic<Any>, group? : Dynamic<Any>, push_mode? : Dynamic<Any>, pop_mode? : Dynamic<Any>, longer_alt? : Dynamic<Any>, line_breaks? : Dynamic<Any>, start_chars_hint? : Dynamic<Any>}) -> {name : String, PATTERN : Dynamic<Any>, CATEGORIES? : Dynamic<Any>, LABEL? : String, GROUP? : Dynamic<Any>, PUSH_MODE? : Dynamic<Any>, POP_MODE? : Dynamic<Any>, LONGER_ALT? : Dynamic<Any>, LINE_BREAKS? : Dynamic<Any>, START_CHARS_HINT? : Dynamic<Any>} {
		return createToken;
	}

	public static get createTokenInstance() : (t : {tokenTypeIdx : Int, tokenType : Any}, e : String, r : Int, n : Int, i : Int, a : Int, o : Int, s : Int) -> {image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any} {
		return createTokenInstance;
	}

	public static get EOF() : {name : String, PATTERN : Dynamic<Any>, CATEGORIES? : Dynamic<Any>, LABEL? : String, GROUP? : Dynamic<Any>, PUSH_MODE? : Dynamic<Any>, POP_MODE? : Dynamic<Any>, LONGER_ALT? : Dynamic<Any>, LINE_BREAKS? : Dynamic<Any>, START_CHARS_HINT? : Dynamic<Any>} {
		return EOF;
	}

	public static get tokenLabel() : (t : Any) -> String {
		return tokenLabel;
	}

	public static get tokenMatcher() : (t : Any, e : Any) -> Bool {
		return tokenMatcher;
	}

	public static get tokenName() : (t : Any) -> String {
		return tokenName;
	}

	public static get defaultParserErrorProvider() : {buildMismatchTokenMessage : (t : {expected : Any, actual : {image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any}, previous : {image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any}, ruleName : String}) -> String, buildNotAllInputParsedMessage : (t : {firstRedundant : {image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any}, ruleName : String}) -> String, buildNoViableAltMessage : (t : {expectedPathsPerAlt : Array<{GATE? : () -> Bool, ALT : () -> Void}>, actual : Array<{image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any}>, previous : {image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any}, customUserDescription? : String, ruleName : String}) -> String, buildEarlyExitMessage : (t : {expectedIterationPaths : Array<{GATE? : () -> Bool, ALT : () -> Void}>, actual : Array<{image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any}>, customUserDescription? : String, ruleName : String}) -> String} {
		return defaultParserErrorProvider;
	}

	public static get EarlyExitException() : Class<EarlyExitException> {
		return EarlyExitException;
	}

	public static get isRecognitionException() : (t : RecognitionException) -> Bool {
		return isRecognitionException;
	}

	public static get MismatchedTokenException() : Class<MismatchedTokenException> {
		return MismatchedTokenException;
	}

	public static get NotAllInputParsedException() : Class<NotAllInputParsedException> {
		return NotAllInputParsedException;
	}

	public static get NoViableAltException() : Class<NoViableAltException> {
		return NoViableAltException;
	}

	public static get defaultLexerErrorProvider() : {buildUnableToPopLexerModeMessage : (t : {image : String, startOffset : Int, endOffset : Int, startLine : Int, endLine : Int, startColumn : Int, endColumn : Int, tokenTypeIdx : Int, tokenType : Any}) -> String, buildUnexpectedCharactersMessage : (t : String, e : Int, r : Int, n : Int, i : Int) -> String} {
		return defaultLexerErrorProvider;
	}

	public static get Alternation() : Class<Alternation> {
		return Alternation;
	}

	public static get Alternative() : Class<Alternative> {
		return Alternative;
	}

	public static get NonTerminal() : Class<NonTerminal> {
		return NonTerminal;
	}

	public static get Option() : Class<Option> {
		return Option;
	}

	public static get Repetition() : Class<Repetition> {
		return Repetition;
	}

	public static get RepetitionMandatory() : Class<RepetitionMandatory> {
		return RepetitionMandatory;
	}

	public static get RepetitionMandatoryWithSeparator() : Class<RepetitionMandatoryWithSeparator> {
		return RepetitionMandatoryWithSeparator;
	}

	public static get RepetitionWithSeparator() : Class<RepetitionWithSeparator> {
		return RepetitionWithSeparator;
	}

	public static get Rule() : Class<Rule> {
		return Rule;
	}

	public static get Terminal() : Class<Terminal> {
		return Terminal;
	}

	public static get serializeGrammar() : (t : Array<Any>) -> Array<Any> {
		return serializeGrammar;
	}

	public static get serializeProduction() : (t : Any) -> Any {
		return serializeProduction;
	}

	public static get GAstVisitor() : Class<GAstVisitor> {
		return GAstVisitor;
	}

	public static clearCache() : Void {
		console.warn(`The clearCache function was 'soft' removed from the Chevrotain API.
	 It performs no action other than printing this message.
	 Please avoid using it as it will be completely removed in the future`);
	}

	public static get createSyntaxDiagramsCode() : (t : Array<Any>, e? : {resourceBase? : String, css? : String}) -> String {
		return createSyntaxDiagramsCode;
	}

	public static get Parser() : Class<Parser> {
		return Parser;
	}
}

/**
 * A class representing a lexer's definition
 *
 * The actual lexer instance is created by using the `Lexer` constructor
 */
class LexerDefinition {

	/**
	 * A string representing the name of the lexer,
	 * this is used for error messages
	 */
	public var name : String;

	/**
	 * An array of token types
	 * @example
	 * javascript
	 * const Lexer = chevrotain.Lexer;
	 * const tokenTypes = chevrotain.createToken({ name: "Plus", pattern: /\+/ });
	 * const lexer = new Lexer(tokenTypes);
	 * 
	 */
	public var tokenTypes : Array<Token>;

	/**
	 * This property is used for MultiMode Lexers.
	 * A MultiMode Lexer can have multiple modes, each mode has its own set of
	 * token types.
	 *
	 * It must contain a dictionary of modes each with a list of Token Types,
	 * and a default mode string.
	 *
	 * @example
	 * javascript
	 * const Lexer = chevrotain.Lexer;
	 * const tokenTypes = chevrotain.createToken({ name: "Plus", pattern: /\+/ });
	 * const lexer = new Lexer({
	 *     modes: {
	 *         "mode1": [tokenTypes],
	 *         "mode2": [tokenTypes]
	 *     },
	 *     defaultMode: "mode1"
	 * });
	 * 
	 */
	public var modes? : Dynamic<Array<Token>>;

	/**
	 * This property is used for MultiMode Lexers.
	 * This is the default mode for the Lexer.
	 * It must be a string which is a key to the `modes` dictionary.
	 *
	 * @example
	 * javascript
	 * const Lexer = chevrotain.Lexer;
	 * const tokenTypes = chevrotain.createToken({ name: "Plus", pattern: /\+/ });
	 * const lexer = new Lexer({
	 *     modes: {
	 *         "mode1": [tokenTypes],
	 *         "mode2": [tokenTypes]
	 *     },
	 *     defaultMode: "mode1"
	 * });
	 *