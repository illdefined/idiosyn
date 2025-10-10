{ ... }: { config, lib, pkgs, ... }: {
  home.packages = with pkgs.llvmPackages; [
    clangUseLLVM
    clang-manpages
    clang-tools
    lld
  ];

  home.file.".clang-format".source = (pkgs.formats.yaml { }).generate "clang-format.yaml" {
    Standard = "Latest";

    # indentation
    UseTab = "AlignWithSpaces";
    NamespaceIndentation = "Inner";
    IndentExternBlock = "NoIndent";

    IndentAccessModifiers = false;
    IndentCaseBlocks = true;
    IndentCaseLabels = false;
    IndentExportBlock = true;
    IndentGotoLabels = false;

    IndentPPDirectives = "AfterHash";

    # lines
    LineEnding = "LF";
    InsertNewlineAtEOF = true;
    ColumnLimit = 120;

    # line continuation
    BinPackArguments = true;
    BinPackParameters = "OnePerLine";

    BreakAfterAttributes = "Always";
    BreakBeforeBinaryOperators = "All";
    BreakBeforeBraces = "Attach";
    BreakBeforeConceptDeclarations = "Always";
    BreakBeforeInlineASMColon = "OnlyMultiline";
    BreakBeforeTemplateCloser = false;
    BreakBeforeTernaryOperators = true;
    BreakBinaryOperations = "RespectPrecedence";
    BreakConstructorInitializers = "AfterColon";
    BreakInheritanceList = "AfterColon";
    BreakTemplateDeclarations = "MultiLine";

    AllowShortBlocksOnASingleLine = "Never";
    AllowShortCaseExpressionOnASingleLine = true;
    AllowShortCaseLabelsOnASingleLine = true;
    AllowShortCompoundRequirementOnASingleLine = true;
    AllowShortEnumsOnASingleLine = false;
    AllowShortFunctionsOnASingleLine = "Empty";
    AllowShortIfStatementsOnASingleLine = "Never";
    AllowShortLambdasOnASingleLine = "Empty";
    AllowShortLoopsOnASingleLine = false;
    AllowShortNamespacesOnASingleLine = false;

    MaxEmptyLinesToKeep = 1;
    EmptyLineAfterAccessModifier = "Never";
    EmptyLineBeforeAccessModifier = "LogicalBlock";
    KeepEmptyLines = {
      AtEndOfFile = false;
      AtStartOfBlock = false;
      AtStartOfFile = false;
    };

    InsertTrailingCommas = "Wrapped";

    # alignment
    PointerAlignment = "Right";
    QualifierAlignment = "Right";
    ReferenceAlignment = "Pointer";

    AlignConsecutiveAssignments = "None";
    AlignConsecutiveBitFields = "None";
    AlignConsecutiveDeclarations = "None";
    AlignConsecutiveMacros = "None";
    AlignEscapedNewlines = "DontAlign";
    AlignOperands = "AlignAfterOperator";
    AlignTrailingComments = "Never";

    # qualifiers
    QualifierOrder = [
      "friend"
      "static"
      "inline"
      "constexpr"
      "type"
      "const"
      "volatile"
      "restrict"
    ];

    # spacing
    SpaceAfterCStyleCast = true;
    SpaceAfterLogicalNot = false;
    SpaceAfterOperatorKeyword = false;
    SpaceAfterTemplateKeyword = false;
    SpaceAroundPointerQualifiers = "Default";
    SpaceBeforeAssignmentOperators = true;
    SpaceBeforeCaseColon = false;
    SpaceBeforeCpp11BracedList = true;
    SpaceBeforeCtorInitializerColon = true;
    SpaceBeforeInheritanceColon = true;
    SpaceBeforeRangeBasedForLoopColon = false;
    SpaceBeforeSquareBrackets = false;
    SpaceInEmptyBraces = "Always";
    SpacesBeforeTrailingComments = 2;
    SpacesInAngles = "Never";
    SpacesInContainerLiterals = false;
    SpacesInParens = "Never";
    SpacesInSquareBrackets = false;

    SpaceBeforeParens = "Custom";
    SpaceBeforeParensOptions = {
      AfterControlStatement = true;
      AfterFunctionDeclarationName = false;
      AfterFunctionDefinitionName = false;
      AfterNot = true;
      AfterOverloadedOperator = false;
      AfterPlacementOperator = true;
      AfterRequiresInClause = true;
      AfterRequiresInExpression = true;
    };

    BitFieldColonSpacing = "None";

    # includes
    IncludeBlocks = "Preserve";

    # literals
    NumericLiteralCase = {
      Prefix = "Lower";
      Suffix = "Lower";
      HexDigit = "Lower";
      ExponentLetter = "Lower";
    };

    IntegerLiteralSeparotor = {
      Binary = 4;
      Decimal = 3;
      DecimalMinDigits = 5;
      Hex = 4;
    };
  };
}
