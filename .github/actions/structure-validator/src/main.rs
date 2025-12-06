//! Git-Core Protocol Structure Validator
//!
//! This tool validates project structure according to Git-Core Protocol rules
//! and outputs violations that can be auto-fixed by Copilot.

use clap::Parser;
use colored::*;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Output as JSON
    #[arg(long)]
    json: bool,

    /// Path to validate (default: current directory)
    #[arg(short, long, default_value = ".")]
    path: String,

    /// Fix violations automatically
    #[arg(long)]
    fix: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct ValidationResult {
    valid: bool,
    needs_fix: bool,
    violations: Vec<Violation>,
    warnings: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct Violation {
    #[serde(rename = "type")]
    violation_type: String,
    severity: String,
    message: String,
    file: Option<String>,
    suggestion: Option<String>,
    auto_fixable: bool,
}

/// Files that are FORBIDDEN in root
const FORBIDDEN_ROOT_FILES: &[&str] = &[
    "TODO.md", "TASKS.md", "BACKLOG.md",
    "PLANNING.md", "ROADMAP.md", "PROGRESS.md",
    "NOTES.md", "SCRATCH.md", "IDEAS.md",
    "STATUS.md", "CHECKLIST.md",
    "TESTING_CHECKLIST.md", "TEST_PLAN.md", "TEST_GUI.md",
    "IMPLEMENTATION_SUMMARY.md", "IMPLEMENTATION.md",
    "SUMMARY.md", "OVERVIEW.md", "REPORT.md",
    "GETTING_STARTED.md", "GUIDE.md", "TUTORIAL.md",
    "QUICKSTART.md", "SETUP.md", "HOWTO.md",
    "INSTRUCTIONS.md", "MANUAL.md",
];

/// Files that ARE ALLOWED in root
const ALLOWED_ROOT_MD: &[&str] = &[
    "README.md", "AGENTS.md", "CHANGELOG.md",
    "CONTRIBUTING.md", "LICENSE.md", "CODE_OF_CONDUCT.md",
];

/// Required structure for Git-Core Protocol
const REQUIRED_DIRS: &[&str] = &[".ai", ".github"];
const REQUIRED_FILES: &[(&str, &str)] = &[
    ("AGENTS.md", "Agent configuration"),
    (".ai/ARCHITECTURE.md", "System architecture"),
    (".github/copilot-instructions.md", "Copilot rules"),
];

fn main() {
    let args = Args::parse();
    let result = validate_structure(&args.path);

    if args.json {
        println!("{}", serde_json::to_string_pretty(&result).unwrap());
    } else {
        print_human_readable(&result);
    }

    if !result.valid {
        std::process::exit(1);
    }
}

fn validate_structure(base_path: &str) -> ValidationResult {
    let mut violations = Vec::new();
    let mut warnings = Vec::new();

    // Check for forbidden files in root
    check_forbidden_files(base_path, &mut violations);

    // Check for required structure
    check_required_structure(base_path, &mut violations, &mut warnings);

    // Check for misplaced files
    check_misplaced_files(base_path, &mut violations);

    // Check markdown files outside allowed locations
    check_markdown_locations(base_path, &mut violations);

    let needs_fix = violations.iter().any(|v| v.auto_fixable);
    let valid = violations.is_empty();

    ValidationResult {
        valid,
        needs_fix,
        violations,
        warnings,
    }
}

fn check_forbidden_files(base_path: &str, violations: &mut Vec<Violation>) {
    for forbidden in FORBIDDEN_ROOT_FILES {
        let file_path = Path::new(base_path).join(forbidden);
        if file_path.exists() {
            violations.push(Violation {
                violation_type: "FORBIDDEN_FILE".to_string(),
                severity: "error".to_string(),
                message: format!("Forbidden file '{}' found in root", forbidden),
                file: Some(forbidden.to_string()),
                suggestion: Some(format!(
                    "Move to docs/agent-docs/ or delete. Content should be in GitHub Issues."
                )),
                auto_fixable: true,
            });
        }
    }
}

fn check_required_structure(
    base_path: &str,
    violations: &mut Vec<Violation>,
    warnings: &mut Vec<String>,
) {
    // Check required directories
    for dir in REQUIRED_DIRS {
        let dir_path = Path::new(base_path).join(dir);
        if !dir_path.exists() {
            violations.push(Violation {
                violation_type: "MISSING_DIRECTORY".to_string(),
                severity: "error".to_string(),
                message: format!("Required directory '{}' is missing", dir),
                file: Some(dir.to_string()),
                suggestion: Some(format!("Create directory: mkdir -p {}", dir)),
                auto_fixable: true,
            });
        }
    }

    // Check required files
    for (file, description) in REQUIRED_FILES {
        let file_path = Path::new(base_path).join(file);
        if !file_path.exists() {
            violations.push(Violation {
                violation_type: "MISSING_FILE".to_string(),
                severity: "warning".to_string(),
                message: format!("Required file '{}' ({}) is missing", file, description),
                file: Some(file.to_string()),
                suggestion: Some(format!("Create file with template content")),
                auto_fixable: true,
            });
        } else {
            // Check if file is empty or just a stub
            if let Ok(content) = fs::read_to_string(&file_path) {
                if content.trim().is_empty() || content.contains("TBD") {
                    warnings.push(format!(
                        "File '{}' appears to be a stub - consider filling it out",
                        file
                    ));
                }
            }
        }
    }
}

fn check_misplaced_files(base_path: &str, violations: &mut Vec<Violation>) {
    let test_patterns = vec![
        (r"^test_.*\.py$", "tests/"),
        (r"^.*_test\.py$", "tests/"),
        (r"^.*\.test\.[jt]s$", "tests/"),
        (r"^.*\.spec\.[jt]s$", "tests/"),
    ];

    for entry in WalkDir::new(base_path)
        .max_depth(1)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let file_name = entry.file_name().to_string_lossy();

        for (pattern, target_dir) in &test_patterns {
            let re = Regex::new(pattern).unwrap();
            if re.is_match(&file_name) {
                violations.push(Violation {
                    violation_type: "MISPLACED_FILE".to_string(),
                    severity: "warning".to_string(),
                    message: format!("Test file '{}' should be in {}", file_name, target_dir),
                    file: Some(file_name.to_string()),
                    suggestion: Some(format!("Move to {}", target_dir)),
                    auto_fixable: true,
                });
            }
        }
    }
}

fn check_markdown_locations(base_path: &str, violations: &mut Vec<Violation>) {
    // Check for unexpected .md files in root
    for entry in WalkDir::new(base_path)
        .max_depth(1)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let path = entry.path();
        if path.is_file() {
            if let Some(ext) = path.extension() {
                if ext == "md" {
                    let file_name = path.file_name().unwrap().to_string_lossy();

                    // Skip allowed files
                    if ALLOWED_ROOT_MD.contains(&file_name.as_ref()) {
                        continue;
                    }

                    // Skip forbidden files (already reported)
                    if FORBIDDEN_ROOT_FILES.contains(&file_name.as_ref()) {
                        continue;
                    }

                    // Check if it matches agent-docs patterns
                    let agent_doc_patterns = vec![
                        "PROMPT_", "RESEARCH_", "STRATEGY_", "SPEC_",
                        "GUIDE_", "REPORT_", "ANALYSIS_",
                    ];

                    let is_agent_doc = agent_doc_patterns
                        .iter()
                        .any(|p| file_name.starts_with(p));

                    if is_agent_doc {
                        violations.push(Violation {
                            violation_type: "MISPLACED_AGENT_DOC".to_string(),
                            severity: "warning".to_string(),
                            message: format!(
                                "Agent doc '{}' should be in docs/agent-docs/",
                                file_name
                            ),
                            file: Some(file_name.to_string()),
                            suggestion: Some("Move to docs/agent-docs/".to_string()),
                            auto_fixable: true,
                        });
                    } else {
                        // Unknown markdown file
                        violations.push(Violation {
                            violation_type: "UNKNOWN_ROOT_MD".to_string(),
                            severity: "info".to_string(),
                            message: format!(
                                "Unexpected markdown file '{}' in root",
                                file_name
                            ),
                            file: Some(file_name.to_string()),
                            suggestion: Some(
                                "Consider moving to docs/ or docs/agent-docs/ if user-requested"
                                    .to_string(),
                            ),
                            auto_fixable: false,
                        });
                    }
                }
            }
        }
    }
}

fn print_human_readable(result: &ValidationResult) {
    println!("\n{}", "🔍 Git-Core Protocol Structure Validation".bold());
    println!("{}", "=".repeat(50));

    if result.valid {
        println!("\n{}", "✅ All checks passed!".green().bold());
    } else {
        println!("\n{}", "❌ Violations found:".red().bold());
        println!();

        for violation in &result.violations {
            let icon = match violation.severity.as_str() {
                "error" => "🔴",
                "warning" => "🟡",
                _ => "🔵",
            };

            println!(
                "{} [{}] {}",
                icon,
                violation.violation_type.yellow(),
                violation.message
            );

            if let Some(file) = &violation.file {
                println!("   📄 File: {}", file.cyan());
            }

            if let Some(suggestion) = &violation.suggestion {
                println!("   💡 Suggestion: {}", suggestion.green());
            }

            if violation.auto_fixable {
                println!("   🤖 {}", "Auto-fixable by Copilot".blue());
            }

            println!();
        }
    }

    if !result.warnings.is_empty() {
        println!("{}", "⚠️  Warnings:".yellow().bold());
        for warning in &result.warnings {
            println!("   • {}", warning);
        }
        println!();
    }

    if result.needs_fix {
        println!(
            "{}",
            "💡 Some violations can be auto-fixed. A PR will be created."
                .cyan()
                .bold()
        );
    }
}
