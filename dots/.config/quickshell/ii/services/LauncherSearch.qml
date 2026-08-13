pragma Singleton

import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string query: ""
    property list<string> fileResults: []

    Timer {
        id: fileSearchTimer
        interval: 150
        repeat: false
        onTriggered: {
            let searchString = root.query.trim();
            if (searchString.startsWith(Config.options.search.prefix.fileSearch)) {
                searchString = StringUtils.cleanPrefix(searchString, Config.options.search.prefix.fileSearch).trim();
            }
            if (searchString.length >= 3) {
                fileSearchProc.search(searchString);
            } else {
                root.fileResults = [];
            }
        }
    }

    Process {
        id: fileSearchProc
        property list<string> resultsBuffer: []

        function search(searchString) {
            fileSearchProc.running = false;
            fileSearchProc.resultsBuffer = [];
            
            const terms = searchString.split(/\s+/).filter(t => t.length > 0);
            if (terms.length === 0) {
                root.fileResults = [];
                return;
            }
            
            const escapedTerms = terms.map(term => "-iwholename '*" + StringUtils.shellSingleQuoteEscape(term) + "*'").join(" ");
            
            fileSearchProc.command = [
                "bash",
                "-c",
                "find /home/julian \\( -name '.*' -o -name 'Android' -o -name 'Dispositivos' -o -name 'GoogleDrive' -o -name 'node_modules' -o -name 'build' -o -name 'out' -o -name 'dist' -o -name 'target' -o -name 'venv' \\) -prune -o " + escapedTerms + " -printf '%y:%p\\n' 2>/dev/null | awk -F/ '{print NF, $0}' | sort -n | cut -d' ' -f2- | head -n 15"
            ];
            fileSearchProc.running = true;
        }

        stdout: SplitParser {
            onRead: line => {
                fileSearchProc.resultsBuffer.push(line);
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.fileResults = fileSearchProc.resultsBuffer;
            }
        }
    }

    onQueryChanged: {
        const cleaned = query.trim();
        if (query.startsWith(Config.options.search.prefix.clipboard) || query.startsWith(Config.options.search.prefix.emojis)) {
            fileSearchTimer.stop();
            fileSearchProc.running = false;
            root.fileResults = [];
            return;
        }

        let checkString = cleaned;
        if (checkString.startsWith(Config.options.search.prefix.fileSearch)) {
            checkString = StringUtils.cleanPrefix(checkString, Config.options.search.prefix.fileSearch).trim();
        }

        if (checkString.length >= 3) {
            fileSearchTimer.restart();
        } else {
            fileSearchTimer.stop();
            fileSearchProc.running = false;
            root.fileResults = [];
        }
    }

    function ensurePrefix(prefix) {
        if ([Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch, Config.options.search.prefix.fileSearch,].some(i => root.query.startsWith(i))) {
            root.query = prefix + root.query.slice(1);
        } else {
            root.query = prefix + root.query;
        }
    }

    // https://specifications.freedesktop.org/menu/latest/category-registry.html
    property list<string> mainRegisteredCategories: ["AudioVideo", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]
    property list<string> appCategories: DesktopEntries.applications.values.reduce((acc, entry) => {
        for (const category of entry.categories) {
            if (!acc.includes(category) && mainRegisteredCategories.includes(category)) {
                acc.push(category);
            }
        }
        return acc;
    }, []).sort()

    // Load user action scripts from ~/.config/illogical-impulse/actions/
    // Uses FolderListModel to auto-reload when scripts are added/removed
    property var userActionScripts: {
        const actions = [];
        for (let i = 0; i < userActionsFolder.count; i++) {
            const fileName = userActionsFolder.get(i, "fileName");
            const filePath = userActionsFolder.get(i, "filePath");
            if (fileName && filePath) {
                const actionName = fileName.replace(/\.[^/.]+$/, ""); // strip extension
                actions.push({
                    action: actionName,
                    execute: ((path) => (args) => {
                        Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
                    })(FileUtils.trimFileProtocol(filePath.toString()))
                });
            }
        }
        return actions;
    }

    FolderListModel {
        id: userActionsFolder
        folder: Qt.resolvedUrl(Directories.userActions)
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    property var searchActions: [
        {
            action: "accentcolor",
            execute: args => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", ...(args != '' ? [`${args}`] : [])]);
            }
        },
        {
            action: "dark",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]);
            }
        },
        {
            action: "konachanwallpaper",
            execute: () => {
                Quickshell.execDetached([Quickshell.shellPath("scripts/colors/random/random_konachan_wall.sh")]);
            }
        },
        {
            action: "light",
            execute: () => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]);
            }
        },
        {
            action: "superpaste",
            execute: args => {
                if (!/^(\d+)/.test(args.trim())) {
                    // Invalid if doesn't start with numbers
                    Quickshell.execDetached(["notify-send", Translation.tr("Superpaste"), Translation.tr("Usage: <tt>%1superpaste NUM_OF_ENTRIES[i]</tt>\nSupply <tt>i</tt> when you want images\nExamples:\n<tt>%1superpaste 4i</tt> for the last 4 images\n<tt>%1superpaste 7</tt> for the last 7 entries").arg(Config.options.search.prefix.action), "-a", "Shell"]);
                    return;
                }
                const syntaxMatch = /^(?:(\d+)(i)?)/.exec(args.trim());
                const count = syntaxMatch[1] ? parseInt(syntaxMatch[1]) : 1;
                const isImage = !!syntaxMatch[2];
                Cliphist.superpaste(count, isImage);
            }
        },
        {
            action: "todo",
            execute: args => {
                Todo.addTask(args);
            }
        },
        {
            action: "wallpaper",
            execute: () => {
                Hyprland.dispatch(`hl.dsp.global("quickshell:wallpaperSelectorToggle")`)
            }
        },
        {
            action: "wipeclipboard",
            execute: () => {
                Cliphist.wipe();
            }
        },
    ]

    // Combined built-in and user actions
    property var allActions: searchActions.concat(userActionScripts)

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = (StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined)
            return false;
        const unsafeKeywords = Config.options.workSafety.triggerCondition.linkKeywords;
        return StringUtils.stringListContainsSubstring(entry.toLowerCase(), unsafeKeywords);
    }

    Timer {
        id: nonAppResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            let expr = root.query;
            if (expr.startsWith(Config.options.search.prefix.math)) {
                expr = expr.slice(Config.options.search.prefix.math.length);
            }
            mathProc.calculateExpression(expr);
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data;
            }
        }
    }

    property list<var> results: {
        // Search results are handled here
        ////////////////// Skip? //////////////////
        if (root.query == "")
            return [];

        ///////////// Special cases ///////////////
        if (root.query.startsWith(Config.options.search.prefix.clipboard)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.clipboard);
            return Cliphist.fuzzyQuery(searchString).map((entry, index, array) => {
                const mightBlurImage = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
                let shouldBlurImage = mightBlurImage;
                if (mightBlurImage) {
                    shouldBlurImage = shouldBlurImage && (root.containsUnsafeLink(array[index - 1]) || root.containsUnsafeLink(array[index + 1]));
                }
                return resultComp.createObject(null, {
                    rawValue: entry,
                    // Image entries are represented by their preview; the cliphist
                    // placeholder ("[[ binary data ... ]]") is not useful to show.
                    name: Cliphist.entryIsImage(entry) ? "" : StringUtils.cleanCliphistEntry(entry),
                    verb: "",
                    // cliphist' numeric ID is internal metadata, not item content.
                    type: "",
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Copy"),
                            iconName: "content_copy",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.copy(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Delete"),
                            iconName: "delete",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        })],
                    blurImage: shouldBlurImage
                });
            }).filter(Boolean);
        } else if (root.query.startsWith(Config.options.search.prefix.emojis)) {
            // Clipboard
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.emojis);
            return Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Emoji"),
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                });
            }).filter(Boolean);
        }

        ////////////////// Init ///////////////////
        nonAppResultsTimer.restart();
        const mathResultObject = resultComp.createObject(null, {
            name: root.mathResult,
            verb: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'calculate',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                Quickshell.clipboardText = root.mathResult;
            }
        });
        const appResultObjects = AppSearch.fuzzyQuery(StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app)).map(entry => {
            return resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    if (!entry.runInTerminal)
                        entry.execute();
                    else {
                        // Probably needs more proper escaping, but this will do for now
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            });
        });
        const commandResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            verb: Translation.tr("Run"),
            type: Translation.tr("Command"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'terminal',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let cleanedCommand = root.query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                if (cleanedCommand.startsWith(Config.options.search.prefix.shellCommand)) {
                    cleanedCommand = cleanedCommand.slice(Config.options.search.prefix.shellCommand.length);
                }
                Quickshell.execDetached(["bash", "-c", root.query.startsWith('sudo') ? `${Config.options.apps.terminal} fish -C '${cleanedCommand}'` : cleanedCommand]);
            }
        });
        const webSearchResultObject = resultComp.createObject(null, {
            name: root.query.startsWith("g ") ? root.query.slice(2) : (root.query.startsWith("google ") ? root.query.slice(7) : StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch)),
            verb: Translation.tr("Search"),
            type: Translation.tr("Google search"),
            iconName: 'google-chrome',
            iconType: LauncherSearchResult.IconType.System,
            execute: () => {
                let query = root.query.startsWith("g ") ? root.query.slice(2) : (root.query.startsWith("google ") ? root.query.slice(7) : StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch));
                let url = Config.options.search.engineBaseUrl + query;
                Qt.openUrlExternally(url);
            }
        });
        const launcherActionObjects = root.allActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            if (actionString.startsWith(root.query) || root.query.startsWith(actionString)) {
                return resultComp.createObject(null, {
                    name: root.query.startsWith(actionString) ? root.query : actionString,
                    verb: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    iconName: 'settings_suggest',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        action.execute(root.query.split(" ").slice(1).join(" "));
                    }
                });
            }
            return null;
        }).filter(Boolean);

        //////// Prioritized by prefix /////////
        let result = [];
        const startsWithFileSearchPrefix = root.query.startsWith(Config.options.search.prefix.fileSearch);

        if (startsWithFileSearchPrefix) {
            if (root.fileResults.length > 0) {
                const fileResultObjects = root.fileResults.map(entry => {
                    const parts = entry.split(":");
                    if (parts.length < 2) return null;
                    const isDir = parts[0] === "d";
                    const filePath = parts.slice(1).join(":");
                    return resultComp.createObject(null, {
                        name: FileUtils.fileNameForPath(filePath),
                        comment: filePath,
                        verb: isDir ? Translation.tr("Open Folder") : Translation.tr("Open File"),
                        type: isDir ? Translation.tr("Folder") : Translation.tr("File"),
                        iconName: isDir ? 'folder' : 'description',
                        iconType: LauncherSearchResult.IconType.Material,
                        execute: () => {
                            Qt.openUrlExternally("file://" + filePath);
                        },
                        actions: [
                            resultComp.createObject(null, {
                                name: Translation.tr("Copy path"),
                                iconName: "content_copy",
                                iconType: LauncherSearchResult.IconType.Material,
                                execute: () => {
                                    Quickshell.clipboardText = filePath;
                                }
                            })
                        ]
                    });
                }).filter(Boolean);
                result = result.concat(fileResultObjects);
            }
            return result;
        }

        const startsWithNumber = /^\d/.test(root.query);
        const startsWithMathPrefix = root.query.startsWith(Config.options.search.prefix.math);
        const startsWithShellCommandPrefix = root.query.startsWith(Config.options.search.prefix.shellCommand);
        const startsWithWebSearchPrefix = root.query.startsWith(Config.options.search.prefix.webSearch) || root.query.startsWith("g ") || root.query.startsWith("google ");

        if (startsWithNumber || startsWithMathPrefix) {
            result.push(mathResultObject);
        } else if (startsWithShellCommandPrefix) {
            result.push(commandResultObject);
        } else if (startsWithWebSearchPrefix) {
            result.push(webSearchResultObject);
        }

        //////////////// Apps //////////////////
        result = result.concat(appResultObjects.slice(0, 8));

        //////////////// Files and Folders //////////////////
        if (root.fileResults.length > 0) {
            const fileResultObjects = root.fileResults.map(entry => {
                const parts = entry.split(":");
                if (parts.length < 2) return null;
                const isDir = parts[0] === "d";
                const filePath = parts.slice(1).join(":");
                return resultComp.createObject(null, {
                    name: FileUtils.fileNameForPath(filePath),
                    comment: filePath,
                    verb: isDir ? Translation.tr("Open Folder") : Translation.tr("Open File"),
                    type: isDir ? Translation.tr("Folder") : Translation.tr("File"),
                    iconName: isDir ? 'folder' : 'description',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        Qt.openUrlExternally("file://" + filePath);
                    },
                    actions: [
                        resultComp.createObject(null, {
                            name: Translation.tr("Copy path"),
                            iconName: "content_copy",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Quickshell.clipboardText = filePath;
                            }
                        })
                    ]
                });
            }).filter(Boolean);
            result = result.concat(fileResultObjects);
        }

        ////////// Launcher actions ////////////
        result = result.concat(launcherActionObjects);

        /// Math result, command, web search ///
        if (Config.options.search.prefix.showDefaultActionsWithoutPrefix) {
            if (!startsWithShellCommandPrefix)
                result.push(commandResultObject);
            if (!startsWithNumber && !startsWithMathPrefix)
                result.push(mathResultObject);
            if (!startsWithWebSearchPrefix)
                result.push(webSearchResultObject);
        }

        return result;
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}
