import SwiftUI

struct EvidenceSourcesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Text("Evidence-Based Mental Health Support")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("All therapeutic techniques and interventions provided by Omni are based on peer-reviewed research and established clinical guidelines from leading mental health organizations.")
                            .font(.body)
                            .foregroundColor(.omniTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.omniCardLavender)
                    .cornerRadius(16)
                    
                    // Academic Sources & Research
                    ExpandableSourceSection(
                        title: "Academic Sources & Research",
                        isExpanded: expandedSections.contains("academic"),
                        onToggle: { toggleSection("academic") }
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            ResearchItem(
                                title: "Color Psychology in Mental Health",
                                authors: "Elliot, A.J., & Maier, M.A.",
                                publication: "Annual Review of Psychology, 2014",
                                description: "Research on how color affects psychological functioning, particularly the calming effects of green and blue hues on anxiety reduction."
                            )
                            
                            ResearchItem(
                                title: "Digital Mental Health Interventions",
                                authors: "Naslund, J.A., et al.",
                                publication: "World Psychiatry, 2021",
                                description: "Systematic review of digital mental health tools and their effectiveness in supporting individuals with anxiety and depression."
                            )
                            
                            ResearchItem(
                                title: "Cognitive Behavioral Therapy Techniques",
                                authors: "Beck, A.T., & Dozois, D.J.",
                                publication: "Annual Review of Medicine, 2011",
                                description: "Evidence-based CBT approaches that form the foundation of our therapeutic conversations and mood tracking features."
                            )
                            
                            ResearchItem(
                                title: "Mindfulness-Based Stress Reduction",
                                authors: "Kabat-Zinn, J.",
                                publication: "Mindfulness-Based Interventions in Context, 2003",
                                description: "Research supporting breathing exercises and mindfulness techniques integrated into the app."
                            )
                        }
                    }
                    
                    // Therapeutic Techniques
                    ExpandableSourceSection(
                        title: "Therapeutic Techniques",
                        isExpanded: expandedSections.contains("techniques"),
                        onToggle: { toggleSection("techniques") }
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            TechniqueItem(
                                name: "4-7-8 Breathing Technique",
                                source: "Dr. Andrew Weil, University of Arizona",
                                description: "A breathing pattern based on ancient pranayama techniques, clinically shown to reduce anxiety and promote relaxation."
                            )
                            
                            TechniqueItem(
                                name: "Mood Tracking & Journaling",
                                source: "American Psychological Association",
                                description: "Regular mood monitoring helps identify patterns and triggers, supporting better emotional regulation and self-awareness."
                            )
                            
                            TechniqueItem(
                                name: "Therapeutic Color Design",
                                source: "Environmental Psychology Research",
                                description: "Use of sage green (#7FB069) and calming blues based on research showing these colors reduce heart rate and anxiety levels."
                            )
                            
                            TechniqueItem(
                                name: "Conversational AI Support",
                                source: "Journal of Medical Internet Research",
                                description: "AI-powered mental health support shown to reduce symptoms of depression and anxiety when used regularly."
                            )
                        }
                    }
                    
                    // Crisis Support Resources
                    ExpandableSourceSection(
                        title: "Crisis Support Resources",
                        isExpanded: expandedSections.contains("crisis"),
                        onToggle: { toggleSection("crisis") }
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            CrisisSourceItem(
                                organization: "988 Suicide & Crisis Lifeline",
                                certification: "SAMHSA-certified",
                                description: "National network of crisis centers providing 24/7 support, funded by the U.S. Department of Health and Human Services."
                            )
                            
                            CrisisSourceItem(
                                organization: "Crisis Text Line",
                                certification: "NCMHC Accredited",
                                description: "Trained crisis counselors providing text-based support, with evidence-based de-escalation techniques."
                            )
                            
                            CrisisSourceItem(
                                organization: "SAMHSA National Helpline",
                                certification: "Federal Government Service",
                                description: "Treatment referral and information service backed by the Substance Abuse and Mental Health Services Administration."
                            )
                        }
                    }
                    
                    // Legal & Ethical Information
                    ExpandableSourceSection(
                        title: "Legal & Ethical Information",
                        isExpanded: expandedSections.contains("legal"),
                        onToggle: { toggleSection("legal") }
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            LegalItem(
                                title: "Privacy & Data Protection",
                                description: "All user data is encrypted using AES-256 encryption. We comply with HIPAA guidelines for mental health data protection."
                            )
                            
                            LegalItem(
                                title: "Ethical Guidelines",
                                description: "Our AI follows ethical guidelines established by the American Psychological Association for digital mental health tools."
                            )
                            
                            LegalItem(
                                title: "Limitations of Service",
                                description: "Omni is a support tool and not a replacement for professional mental health treatment. Users experiencing crisis should contact emergency services."
                            )
                            
                            LegalItem(
                                title: "Mandated Reporting",
                                description: "While Omni maintains user privacy, we comply with legal requirements for reporting when users indicate immediate risk of harm."
                            )
                        }
                    }
                    
                    // Additional Resources
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Resources")
                            .font(.headline)
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("For more information about our evidence-based approach and to access full research papers, please visit our website or contact our research team.")
                            .font(.subheadline)
                            .foregroundColor(.omniTextSecondary)
                        
                        Button(action: {
                            if let url = URL(string: "https://www.omniapp.com/research") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Text("Visit Research Portal")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.omniCardSoftBlue)
                    .cornerRadius(16)
                }
                .padding()
            }
            .background(Color.omniBackground)
            .navigationTitle("Evidence & Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                }
            }
        }
    }
    
    private func toggleSection(_ section: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}

struct ExpandableSourceSection<Content: View>: View {
    let title: String
    let isExpanded: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.omniTextPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextTertiary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                content()
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.omniCardBeige)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

struct ResearchItem: View {
    let title: String
    let authors: String
    let publication: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.omniTextPrimary)
            
            Text("\(authors) - \(publication)")
                .font(.caption)
                .foregroundColor(.omniTextTertiary)
                .italic()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.omniTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

struct TechniqueItem: View {
    let name: String
    let source: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.omniTextPrimary)
            
            Text(source)
                .font(.caption)
                .foregroundColor(.omniTextTertiary)
                .italic()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.omniTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

struct CrisisSourceItem: View {
    let organization: String
    let certification: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(organization)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.omniTextPrimary)
                
                Text("• \(certification)")
                    .font(.caption)
                    .foregroundColor(.omniPrimary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.omniTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

struct LegalItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.omniTextPrimary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.omniTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EvidenceSourcesView()
}