// Copyright (c) 2026 actimov2. Licensed under MIT.

#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

class FToolBarBuilder;
class FMenuBuilder;
class FUICommandList;

/**
 * SamplePlugin module — adds a "Hello" button to the Unreal Editor's main toolbar.
 *
 * Use this as a template for any editor-extending plugin. The pattern is:
 *   1. StartupModule() registers the toolbar extension
 *   2. ShutdownModule() unregisters cleanly so hot-reload works
 *   3. ButtonClicked() runs your actual logic
 */
class FSamplePluginModule : public IModuleInterface
{
public:
	/** IModuleInterface implementation */
	virtual void StartupModule() override;
	virtual void ShutdownModule() override;

private:
	/** Registers our menu/toolbar extensions after ToolMenus is ready. */
	void RegisterMenus();

	/** Called when the user clicks the toolbar button. */
	void OnToolbarButtonClicked();

	TSharedPtr<FUICommandList> PluginCommands;
};
