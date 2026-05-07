// Copyright (c) 2026 actimov2. Licensed under MIT.

#include "SamplePlugin.h"
#include "SamplePluginCommands.h"

#include "ToolMenus.h"
#include "Framework/MultiBox/MultiBoxBuilder.h"
#include "Misc/MessageDialog.h"

#define LOCTEXT_NAMESPACE "FSamplePluginModule"

void FSamplePluginModule::StartupModule()
{
	// Register UI commands
	FSamplePluginCommands::Register();

	PluginCommands = MakeShareable(new FUICommandList);
	PluginCommands->MapAction(
		FSamplePluginCommands::Get().SayHelloCommand,
		FExecuteAction::CreateRaw(this, &FSamplePluginModule::OnToolbarButtonClicked),
		FCanExecuteAction());

	// Wait for ToolMenus, then add our toolbar button.
	UToolMenus::RegisterStartupCallback(
		FSimpleMulticastDelegate::FDelegate::CreateRaw(this, &FSamplePluginModule::RegisterMenus));
}

void FSamplePluginModule::ShutdownModule()
{
	UToolMenus::UnRegisterStartupCallback(this);
	UToolMenus::UnregisterOwner(this);

	FSamplePluginCommands::Unregister();
}

void FSamplePluginModule::RegisterMenus()
{
	FToolMenuOwnerScoped OwnerScoped(this);

	// Add a button to the main level editor toolbar
	UToolMenu* ToolbarMenu = UToolMenus::Get()->ExtendMenu("LevelEditor.LevelEditorToolBar.PlayToolBar");
	if (ToolbarMenu)
	{
		FToolMenuSection& Section = ToolbarMenu->FindOrAddSection("PluginTools");
		FToolMenuEntry& Entry = Section.AddEntry(FToolMenuEntry::InitToolBarButton(
			FSamplePluginCommands::Get().SayHelloCommand));
		Entry.SetCommandList(PluginCommands);
	}
}

void FSamplePluginModule::OnToolbarButtonClicked()
{
	FMessageDialog::Open(
		EAppMsgType::Ok,
		LOCTEXT("HelloMessage",
			"Hello from SamplePlugin!\n\n"
			"This is a minimal editor plugin loaded from your Unreal_Nice_Plugins repo.\n"
			"Edit Source/SamplePlugin/Private/SamplePlugin.cpp to change this message."));
}

#undef LOCTEXT_NAMESPACE

IMPLEMENT_MODULE(FSamplePluginModule, SamplePlugin)
