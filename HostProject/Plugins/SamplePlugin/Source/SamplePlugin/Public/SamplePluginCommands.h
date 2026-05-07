// Copyright (c) 2026 actimov2. Licensed under MIT.

#pragma once

#include "CoreMinimal.h"
#include "Framework/Commands/Commands.h"
#include "Styling/AppStyle.h"

class FSamplePluginCommands : public TCommands<FSamplePluginCommands>
{
public:
	FSamplePluginCommands()
		: TCommands<FSamplePluginCommands>(
			TEXT("SamplePlugin"),
			NSLOCTEXT("Contexts", "SamplePlugin", "SamplePlugin"),
			NAME_None,
			FAppStyle::GetAppStyleSetName())
	{
	}

	/** Register all UI commands declared below. */
	virtual void RegisterCommands() override;

	TSharedPtr<FUICommandInfo> SayHelloCommand;
};
