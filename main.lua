#include "imgui.h"
#include <string>

static bool PinkToggle(const char* label, bool* v)
{
    ImDrawList* draw = ImGui::GetWindowDrawList();
    ImVec2 p = ImGui::GetCursorScreenPos();

    ImGui::InvisibleButton(label, ImVec2(220, 20));
    if (ImGui::IsItemClicked())
        *v = !*v;

    ImU32 off = ImGui::GetColorU32(ImVec4(0.13f, 0.13f, 0.14f, 1.0f));
    ImU32 on  = ImGui::GetColorU32(ImVec4(1.00f, 0.62f, 0.90f, 1.0f));
    ImU32 txt = ImGui::GetColorU32(*v ? ImVec4(0.90f, 0.90f, 0.92f, 1.0f)
                                      : ImVec4(0.45f, 0.45f, 0.47f, 1.0f));

    draw->AddCircleFilled(ImVec2(p.x + 9, p.y + 10), 8.5f, *v ? on : off, 24);
    draw->AddText(ImVec2(p.x + 25, p.y + 2), txt, label);

    return *v;
}

static void PinkSlider(const char* label, float* value, float min, float max)
{
    ImGui::TextUnformatted(label);
    ImGui::SetNextItemWidth(-1);
    ImGui::SliderFloat((std::string("##") + label).c_str(), value, min, max, "%.2f");
}

static void PinkCombo(const char* label, int* current, const char* const* items, int count)
{
    ImGui::TextUnformatted(label);
    ImGui::SetNextItemWidth(-1);
    ImGui::Combo((std::string("##") + label).c_str(), current, items, count);
}

static void PinkPanelBegin(const char* name, float height)
{
    ImGui::BeginChild(name, ImVec2(0, height), true);
    ImGui::TextUnformatted(name);
    ImGui::Spacing();
}

static void PinkPanelEnd()
{
    ImGui::EndChild();
    ImGui::Spacing();
}

static void ApplyPinkExternalStyle()
{
    ImGuiStyle& s = ImGui::GetStyle();

    s.WindowRounding = 4.0f;
    s.ChildRounding = 4.0f;
    s.FrameRounding = 8.0f;
    s.GrabRounding = 8.0f;
    s.ScrollbarRounding = 8.0f;
    s.WindowPadding = ImVec2(10, 8);
    s.FramePadding = ImVec2(8, 4);
    s.ItemSpacing = ImVec2(7, 6);

    ImVec4* c = s.Colors;
    c[ImGuiCol_WindowBg]        = ImVec4(0.025f, 0.025f, 0.030f, 0.96f);
    c[ImGuiCol_ChildBg]         = ImVec4(0.035f, 0.035f, 0.040f, 0.92f);
    c[ImGuiCol_Border]          = ImVec4(0.10f, 0.10f, 0.11f, 1.00f);
    c[ImGuiCol_Text]            = ImVec4(0.88f, 0.88f, 0.90f, 1.00f);
    c[ImGuiCol_TextDisabled]    = ImVec4(0.42f, 0.42f, 0.45f, 1.00f);

    c[ImGuiCol_FrameBg]         = ImVec4(0.17f, 0.17f, 0.17f, 1.00f);
    c[ImGuiCol_FrameBgHovered]  = ImVec4(0.22f, 0.22f, 0.22f, 1.00f);
    c[ImGuiCol_FrameBgActive]   = ImVec4(0.25f, 0.18f, 0.23f, 1.00f);

    c[ImGuiCol_SliderGrab]      = ImVec4(1.00f, 0.68f, 0.92f, 1.00f);
    c[ImGuiCol_SliderGrabActive]= ImVec4(1.00f, 0.50f, 0.86f, 1.00f);

    c[ImGuiCol_Button]          = ImVec4(0.08f, 0.08f, 0.09f, 1.00f);
    c[ImGuiCol_ButtonHovered]   = ImVec4(0.16f, 0.13f, 0.16f, 1.00f);
    c[ImGuiCol_ButtonActive]    = ImVec4(0.24f, 0.16f, 0.22f, 1.00f);

    c[ImGuiCol_Header]          = ImVec4(0.13f, 0.10f, 0.13f, 1.00f);
    c[ImGuiCol_HeaderHovered]   = ImVec4(0.22f, 0.15f, 0.20f, 1.00f);
    c[ImGuiCol_HeaderActive]    = ImVec4(0.28f, 0.18f, 0.25f, 1.00f);

    c[ImGuiCol_CheckMark]       = ImVec4(1.00f, 0.65f, 0.92f, 1.00f);
}

void DrawPinkImGuiMockup()
{
    ApplyPinkExternalStyle();

    static int tab = 0;
    const char* tabs[] = {
        "Main", "Visual", "Input", "Output", "Options", "Viewer", "List"
    };

    static bool toggleA = false;
    static bool toggleB = true;
    static bool toggleC = false;
    static bool toggleD = false;
    static bool toggleE = true;
    static bool toggleF = false;
    static bool toggleG = true;
    static bool toggleH = false;

    static float sliderA = 35.0f;
    static float sliderB = 70.0f;
    static float sliderC = 15.0f;
    static float sliderD = 0.65f;
    static float sliderE = 120.0f;
    static float sliderF = 8.0f;

    static int comboA = 0;
    static int comboB = 1;
    static int comboC = 0;

    const char* modes[] = { "Smooth", "Sharp", "Soft" };
    const char* styles[] = { "Rounded", "Compact", "Classic" };
    const char* themes[] = { "Pink", "Blue", "Mono" };

    ImGui::SetNextWindowSize(ImVec2(535, 720), ImGuiCond_FirstUseEver);
    ImGui::Begin("matcha-style ui mockup", nullptr, ImGuiWindowFlags_NoCollapse);

    for (int i = 0; i < IM_ARRAYSIZE(tabs); i++)
    {
        if (i > 0)
            ImGui::SameLine();

        if (ImGui::Selectable(tabs[i], tab == i, 0, ImVec2(0, 22)))
            tab = i;
    }

    ImGui::Separator();

    if (tab == 0)
    {
        float gap = 10.0f;
        float width = (ImGui::GetContentRegionAvail().x - gap) * 0.5f;

        ImGui::BeginChild("left_column", ImVec2(width, 0), false);

        PinkPanelBegin("Controls", 210);
        PinkToggle("Enabled", &toggleA);
        PinkToggle("Show Indicator", &toggleB);
        PinkToggle("Use Advanced Mode", &toggleC);
        PinkCombo("Primary Mode", &comboA, modes, IM_ARRAYSIZE(modes));
        PinkCombo("Style", &comboB, styles, IM_ARRAYSIZE(styles));
        PinkSlider("Amount", &sliderA, 0.0f, 100.0f);
        PinkPanelEnd();

        PinkPanelBegin("Adjustment", 220);
        PinkToggle("Auto Adjust", &toggleD);
        PinkToggle("Fine Tune", &toggleE);
        PinkSlider("Horizontal", &sliderB, 0.0f, 100.0f);
        PinkSlider("Vertical", &sliderC, 0.0f, 100.0f);
        PinkSlider("Blend", &sliderD, 0.0f, 1.0f);
        PinkPanelEnd();

        PinkPanelBegin("Keybinds", 120);
        PinkToggle("Hold Mode", &toggleF);
        ImGui::SameLine(165);
        ImGui::Button("R", ImVec2(62, 22));

        PinkToggle("Toggle Mode", &toggleG);
        ImGui::SameLine(165);
        ImGui::Button("Q", ImVec2(62, 22));
        PinkPanelEnd();

        ImGui::EndChild();

        ImGui::SameLine(0, gap);

        ImGui::BeginChild("right_column", ImVec2(width, 0), false);

        PinkPanelBegin("Display", 200);
        PinkToggle("Visible", &toggleH);
        PinkToggle("Filled", &toggleA);
        PinkToggle("Outline", &toggleB);
        PinkSlider("Size", &sliderE, 0.0f, 500.0f);
        PinkCombo("Theme", &comboC, themes, IM_ARRAYSIZE(themes));
        PinkPanelEnd();

        PinkPanelBegin("Motion", 180);
        PinkToggle("Animated", &toggleC);
        PinkToggle("Responsive", &toggleD);
        PinkSlider("Speed", &sliderF, 0.0f, 20.0f);
        PinkSlider("Smoothing", &sliderD, 0.0f, 1.0f);
        PinkPanelEnd();

        PinkPanelBegin("Miscellaneous", 160);
        PinkToggle("Notifications", &toggleE);
        PinkToggle("Sounds", &toggleF);
        PinkToggle("Save State", &toggleG);
        ImGui::Button("Reset", ImVec2(80, 24));
        ImGui::SameLine();
        ImGui::Button("Apply", ImVec2(80, 24));
        PinkPanelEnd();

        ImGui::EndChild();
    }
    else
    {
        PinkPanelBegin("Placeholder", 160);
        ImGui::TextDisabled("Empty tab for layout testing.");
        PinkToggle("Example Toggle", &toggleA);
        PinkSlider("Example Slider", &sliderA, 0.0f, 100.0f);
        PinkPanelEnd();
    }

    ImGui::End();

    ImGui::SetNextWindowSize(ImVec2(120, 44), ImGuiCond_FirstUseEver);
    ImGui::Begin("Small Panel", nullptr,
        ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize);

    ImGui::TextColored(ImVec4(1.0f, 0.68f, 0.92f, 1.0f), "Keybind List");

    ImGui::End();
}
