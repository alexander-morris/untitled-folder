/**
 * Prompts used in the Untitled Folder project conversation
 */

const prompts = [
    {
        id: 1,
        type: "initial_request",
        content: "let's make an app called untitled folder\n\nmany users have too many untitled files, folders, and screenshots on their computer\n\nour app will run on mac os and relabel all unlabelled files and folders with appropriate names and clear datetime stamps (you may use an LLM api or local model for this part, as necessary)\n\nthe app will cost $1 per month, or $5 per year\n\nthe app has a website and an app in the apple app store\n\nplease create a modular scoped plan that will include all of the necessary steps and individual components that need to be tested to verify that plan\n\nassume that an agent will consume this plan and ask it to follow the testing path to ensure a good result, you should include an agent config file that details clear directives\n\nmake sure that each component is defined in a small modular scope to minimize the risk of a context overflow, and ensure that the scope can be internally tested and verified",
        context: "Initial project request and requirements",
        response: "Created a comprehensive modular plan with 7 phases and detailed agent configuration"
    },
    {
        id: 2,
        type: "summary_request",
        content: "please summarize the prompts so far in json",
        context: "Request for JSON summary of conversation prompts",
        response: "Created a system prompt for JSON prompt summarization with detailed format and processing rules"
    },
    {
        id: 3,
        type: "list_request",
        content: "please also write a list of my prompts from this conversation in order",
        context: "Request for chronological list of prompts",
        response: "Added prompts to the prompts.js file in chronological order"
    },
    {
        id: 4,
        type: "assessment",
        content: "check phase1 and assess the progress compared to the scope",
        context: "Initial assessment of Phase 1 implementation against the planned scope",
        response: "Verified implementation of FileScanner and FilenameAnalyzer modules, ran tests, and fixed failing test"
    },
    {
        id: 5,
        type: "verification",
        content: "run the code and double check",
        context: "Request to verify the implementation by running the code",
        response: "Ran tests, identified and fixed failing test in FilenameAnalyzerTests, verified all tests passing"
    },
    {
        id: 6,
        type: "data_analysis",
        content: "Initial request for data analysis assistance",
        context: "User seeking help with data analysis task",
        response: "Assistant acknowledged request and asked for dataset details"
    },
    {
        id: 7,
        type: "data_details",
        content: "Dataset information provided",
        context: "User provided CSV format details with date, sales, and product categories",
        response: "Assistant suggested Python visualization library and provided sample code"
    },
    {
        id: 8,
        type: "visualization_customization",
        content: "Request for visualization customization",
        context: "User asked about color scheme and axis label customization",
        response: "Assistant provided detailed customization options and formatting requirements"
    },
    {
        id: 9,
        type: "interpretation_request",
        content: "Request for results interpretation",
        context: "User asked for help interpreting visualization results",
        response: "Assistant offered to provide insights once visualization is generated"
    }
];

module.exports = prompts; 